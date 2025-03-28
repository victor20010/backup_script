import os
import sys
import subprocess
import asyncio
import aiofiles
import logging
import tempfile
import json
import shutil
import platform
import multiprocessing
import threading
import time
import re
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional, List, Dict, Any, Set, Union, Tuple
from dataclasses import dataclass, asdict
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.backends import default_backend
import base64
import lz4.frame
import tarfile
import hashlib
import atexit
import tkinter as tk
from tkinter import filedialog, messagebox, ttk
import argparse
import aiohttp
from aiohttp import BasicAuth, FormData
from urllib.parse import urljoin
import keyring  # For secure token management

# Check Python version
if sys.version_info < (3, 9):
    sys.exit("Python 3.9 or higher is required.")

# List of required packages
REQUIRED_PACKAGES = [
    "adb-shell",  # Replaced adb-async with adb-shell for better root support
    "aiofiles",
    "cryptography",
    "lz4",
    "aiohttp",
    "keyring",
    "tqdm",      # For progress bars
    "psutil"     # For system resource monitoring
]

def check_and_install_packages():
    """Check for required packages and install them if missing."""
    for package in REQUIRED_PACKAGES:
        try:
            __import__(package.replace("-", "_"))
        except ImportError:
            print(f"Installing missing package: {package}")
            subprocess.check_call([sys.executable, "-m", "pip", "install", package])

# Check and install required packages
check_and_install_packages()

# Now import packages that might have just been installed
from adb_shell.adb_device import AdbDeviceUsb, AdbDeviceTcp
from adb_shell.auth.sign_pythonrsa import PythonRSASigner
from adb_shell.auth.keygen import keygen
import psutil
from tqdm import tqdm

# --- Exception Handling ---
class BackupError(Exception):
    """Base class for backup-related errors"""
    pass

class RecoverableError(BackupError):
    """Transient errors that can be retried (e.g., network issues)"""
    pass

class CriticalError(BackupError):
    """Fatal errors requiring immediate termination (e.g., invalid credentials)"""
    pass

class CloudManager:
    """Handles cloud backup operations using OAuth2"""
    def __init__(self, base_url: str, access_token: str = None, refresh_token: str = None):
        self.base_url = base_url
        self.access_token = access_token
        self.refresh_token = refresh_token
        self.session = aiohttp.ClientSession()
        self.token_url = urljoin(base_url, "/auth/token")

    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.close()

    async def close(self):
        """Close the session"""
        if self.session:
            await self.session.close()

    async def refresh_access_token(self):
        """Refresh OAuth2 access token"""
        if not self.refresh_token:
            raise CriticalError("No refresh token available")
            
        auth = BasicAuth("android_client", "")
        data = {
            "grant_type": "refresh_token",
            "refresh_token": self.refresh_token
        }
        
        async with self.session.post(self.token_url, data=data, auth=auth) as resp:
            if resp.status == 200:
                token_data = await resp.json()
                self.access_token = token_data['access_token']
                self.refresh_token = token_data.get('refresh_token', self.refresh_token)
                
                # Save tokens securely
                keyring.set_password("android_backup", "access_token", self.access_token)
                keyring.set_password("android_backup", "refresh_token", self.refresh_token)
                return True
            return False

    async def upload_backup(self, backup_path: Path, metadata: dict) -> Dict:
        """Upload encrypted backup to cloud storage with progress tracking"""
        upload_url = urljoin(self.base_url, "/api/v1/backups/upload")
        headers = {"Authorization": f"Bearer {self.access_token}"}
        
        # Get file size for progress tracking
        total_size = os.path.getsize(backup_path)
        
        # Special FormData class that tracks upload progress
        class ProgressFormData(FormData):
            def __init__(self, *args, **kwargs):
                super().__init__(*args, **kwargs)
                self.uploaded_bytes = 0
                self.total_bytes = total_size
                self.last_update = time.time()
            
            async def write(self, writer, *args, **kwargs):
                original_write = writer.write
                
                async def write_with_progress(chunk):
                    self.uploaded_bytes += len(chunk)
                    now = time.time()
                    # Update progress every 0.5 seconds
                    if now - self.last_update > 0.5:
                        percent = min(100, int(self.uploaded_bytes * 100 / self.total_bytes))
                        print(f"\rUploading: {percent}% ({self.uploaded_bytes/1024/1024:.1f} MB / {self.total_bytes/1024/1024:.1f} MB)", end='')
                        self.last_update = now
                    return await original_write(chunk)
                
                writer.write = write_with_progress
                result = await super().write(writer, *args, **kwargs)
                writer.write = original_write
                return result
        
        form = ProgressFormData()
        form.add_field('file', 
                      open(backup_path, 'rb'),
                      filename=backup_path.name,
                      content_type='application/octet-stream')
        form.add_field('metadata', json.dumps(metadata))
        
        try:
            async with self.session.post(upload_url, headers=headers, data=form, timeout=3600) as resp:
                if resp.status == 401:  # Token expired
                    print("\nAccess token expired, refreshing...")
                    if await self.refresh_access_token():
                        return await self.upload_backup(backup_path, metadata)
                    raise CriticalError("Authentication failed")
                
                # Complete progress
                print("\rUploading: 100% (Complete)")
                
                if resp.status != 201:
                    resp_text = await resp.text()
                    raise CriticalError(f"Upload failed with status {resp.status}: {resp_text}")
                
                response_data = await resp.json()
                print(f"Upload successful. Backup ID: {response_data.get('id', 'unknown')}")
                return response_data
        except aiohttp.ClientError as e:
            raise RecoverableError(f"Network error during upload: {str(e)}")

@dataclass
class DeviceInfo:
    """Device information container"""
    model: str
    android_version: str
    sdk_version: str
    serial: str
    is_rooted: bool
    cpu_cores: int
    total_memory: int
    storage_free: int
    backup_date: str
    encryption_enabled: bool
    manufacturer: str = "Unknown"
    bootloader_unlocked: bool = False
    imei: str = None
    wifi_mac: str = None
    battery_level: int = 0
    battery_charging: bool = False

class Config:
    """Secure configuration container"""
    def __init__(self):
        # Backup options
        self.compression_level = 6
        self.compression_method = "zstd"  # Options: zstd, tar (no compression), lz4
        self.chunk_size = 4 * 1024 * 1024  # 4MB chunks
        self.max_retries = 3
        self.exclude_dirs = {'cache', 'code_cache', 'lib', 'app_webview'}
        self.encryption_enabled = True
        self.verify_restore = True
        self.backup_system_apps = False
        
        # System whitelist (similar to YAWAsau's script)
        self.system_whitelist = [
            "com.google.android.gms",
            "com.google.android.gsf",
            "com.android.vending"
        ]
        
        # Performance settings
        self.parallel_processes = max(1, multiprocessing.cpu_count() - 1)
        self.parallel_threads = multiprocessing.cpu_count() * 2
        self.max_concurrent_tasks = 50  # Task throttling
        
        # Security settings
        self.pbkdf2_iterations = 600000  # OWASP recommended
        
        # Storage settings
        self.backup_root = Path.home() / "AndroidBackup"
        self.min_free_space_percent = 15  # Minimum free space required

class UltimateAndroidBackup:
    def __init__(self, password: Optional[str] = None, 
                 cloud_config: Optional[dict] = None,
                 config: Optional[Config] = None):
        self.config = config if config else Config()
        self.platform = platform.system().lower()
        self.logger = self._setup_logger()
        self.backup_root = self._get_backup_root()
        self.device = None
        self.adb_path = self._find_adb_path()
        self.device_info = None
        self.fernet = None
        self.encryption_salt = None
        self.cloud = None
        
        self._setup_encryption(password)
        
        # Initialize cloud manager if cloud config is provided
        if cloud_config:
            self.cloud = CloudManager(
                base_url=cloud_config['base_url'],
                access_token=cloud_config.get('access_token'),
                refresh_token=cloud_config.get('refresh_token')
            )
        
        # Resource management
        self.thread_pool = ThreadPoolExecutor(max_workers=self.config.parallel_threads)
        self.process_pool = ProcessPoolExecutor(max_workers=self.config.parallel_processes)
        
        # State tracking
        self._progress = {'total': 0, 'completed': 0, 'errors': []}
        self._start_time = None
        self.manifest = {}
        self._package_count = 0
        self._backup_dir = None

    def _setup_encryption(self, password: Optional[str]):
        """Initialize encryption with secure parameters"""
        if password and self.config.encryption_enabled:
            self.encryption_salt = os.urandom(16)
            kdf = PBKDF2HMAC(
                algorithm=hashes.SHA512(),
                length=32,
                salt=self.encryption_salt,
                iterations=self.config.pbkdf2_iterations,
                backend=default_backend()
            )
            key = base64.urlsafe_b64encode(kdf.derive(password.encode()))
            self.fernet = Fernet(key)

    def _find_adb_path(self) -> str:
        """Find ADB binary in PATH or in known locations"""
        # Try to find in PATH first
        if self.platform == 'windows':
            adb_cmd = "adb.exe"
            known_paths = [
                os.path.join(os.environ.get('LOCALAPPDATA', ''), 'Android', 'Sdk', 'platform-tools', 'adb.exe'),
                os.path.join(os.environ.get('PROGRAMFILES', ''), 'Android', 'android-sdk', 'platform-tools', 'adb.exe'),
            ]
        else:
            adb_cmd = "adb"
            known_paths = [
                "/usr/bin/adb",
                "/usr/local/bin/adb",
                os.path.expanduser("~/Android/Sdk/platform-tools/adb"),
            ]
            
        # Check in PATH
        if shutil.which(adb_cmd):
            return shutil.which(adb_cmd)
            
        # Check known locations
        for path in known_paths:
            if os.path.isfile(path):
                return path
                
        # If not found, return just the command name and hope it's in PATH
        return adb_cmd

    async def _init_device(self):
        """Initialize ADB connection with advanced error handling"""
        try:
            # Try to connect to device
            self.logger.info("Connecting to Android device...")
            
            # Check if ADB server is running
            try:
                subprocess.run([self.adb_path, "start-server"], check=True, 
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            except Exception as e:
                self.logger.warning(f"Failed to start ADB server: {str(e)}")
            
            # Get connected devices
            result = subprocess.run(
                [self.adb_path, "devices"], 
                check=True, 
                capture_output=True, 
                text=True
            )
            
            devices = []
            for line in result.stdout.splitlines()[1:]:  # Skip the first line which is the header
                if "\t" in line:
                    parts = line.split("\t")
                    if len(parts) >= 2 and parts[1] == "device":
                        devices.append(parts[0])
            
            if not devices:
                raise CriticalError("No devices found. Make sure your device is connected and USB debugging is enabled.")
            
            selected_device = devices[0]
            if len(devices) > 1:
                # If multiple devices are connected, prompt user to select one
                print("Multiple devices found:")
                for i, device in enumerate(devices):
                    print(f"{i+1}: {device}")
                selection = input("Select a device (number): ")
                try:
                    idx = int(selection) - 1
                    if 0 <= idx < len(devices):
                        selected_device = devices[idx]
                    else:
                        self.logger.warning(f"Invalid selection, using first device: {devices[0]}")
                except ValueError:
                    self.logger.warning(f"Invalid input, using first device: {devices[0]}")
            
            # Create ADB connection
            self.logger.info(f"Connecting to device: {selected_device}")
            
            # Generate RSA key pair for authentication if needed
            key_path = Path.home() / ".android" / "adbkey"
            if not key_path.exists():
                os.makedirs(key_path.parent, exist_ok=True)
                keygen(key_path)
            
            with open(key_path, 'rb') as f:
                private_key = f.read()
            signer = PythonRSASigner(private_key, key_path.with_suffix('.pub').read_bytes())
            
            # Connect to device
            if "." in selected_device:  # IP address format for TCP
                host, port = selected_device.split(":", 1) if ":" in selected_device else (selected_device, 5555)
                self.device = AdbDeviceTcp(host=host, port=int(port), default_transport_timeout_s=60)
            else:
                self.device = AdbDeviceUsb(serial=selected_device, default_transport_timeout_s=60)
            
            self.device.connect(rsa_keys=[signer], auth_timeout_s=30)
            
            # Get device properties
            props_cmd = "getprop"
            props_output = self.device.shell(props_cmd)
            props = {}
            
            # Parse getprop output
            for line in props_output.splitlines():
                match = re.match(r'\[([^\]]+)\]: \[([^\]]*)\]', line)
                if match:
                    key, value = match.groups()
                    props[key] = value
            
            # Check for root access
            is_rooted = await self._check_root()
            
            # Get storage info
            storage_free = await self._get_storage_free()
            
            # Get battery info
            battery_level, battery_charging = await self._get_battery_info()
            
            # Check bootloader status
            bootloader_unlocked = props.get('ro.boot.flash.locked', '1') == '0'
            
            # Create device info
            self.device_info = DeviceInfo(
                model=props.get('ro.product.model', 'Unknown'),
                manufacturer=props.get('ro.product.manufacturer', 'Unknown'),
                android_version=props.get('ro.build.version.release', 'Unknown'),
                sdk_version=props.get('ro.build.version.sdk', '0'),
                serial=selected_device,
                is_rooted=is_rooted,
                cpu_cores=int(props.get('ro.product.cpu.cores', 1)),
                total_memory=self._parse_memory_size(props.get('ro.product.ram.size', '0')),
                storage_free=storage_free,
                backup_date=datetime.now().isoformat(),
                encryption_enabled=self.config.encryption_enabled,
                bootloader_unlocked=bootloader_unlocked,
                imei=props.get('persist.radio.imei', None),
                wifi_mac=await self._get_wifi_mac(),
                battery_level=battery_level,
                battery_charging=battery_charging
            )
            
            self.logger.info(f"Connected to {self.device_info.manufacturer} {self.device_info.model} "
                             f"(Android {self.device_info.android_version}, SDK {self.device_info.sdk_version})")
            
            # Validate backup environment
            await self._validate_backup_environment()
            
            return True
        except Exception as e:
            self.logger.error(f"Device connection failed: {str(e)}")
            raise CriticalError(f"Device connection failed: {str(e)}")

    async def _check_root(self) -> bool:
        """Check if device has root access"""
        try:
            # Try with su command
            result = self.device.shell("su -c 'whoami'")
            if "root" in result.lower() or "uid=0" in result.lower():
                self.logger.info("Root access confirmed (su)")
                return True
            
            # Try direct access to /data
            result = self.device.shell("ls -la /data/data")
            if "Permission denied" not in result.lower() and "opendir failed" not in result.lower():
                self.logger.info("Root access confirmed (direct access)")
                return True
                
            # Try using mount command (requires root)
            result = self.device.shell("mount | grep '/data'")
            if "/data" in result:
                self.logger.info("Root access confirmed (mount command)")
                return True
                
            self.logger.warning("Root access not detected. Some features will be unavailable.")
            return False
        except Exception as e:
            self.logger.warning(f"Error checking root access: {str(e)}")
            return False

    async def _get_storage_free(self) -> int:
        """Get available storage space on device in bytes"""
        try:
            output = self.device.shell("df -h /data")
            # Parse output and extract available space
            for line in output.strip().split('\n'):
                if '/data' in line:
                    parts = line.split()
                    if len(parts) >= 4:
                        # Get available space (4th column)
                        avail = parts[3]
                        # Convert to bytes
                        if avail.endswith('G'):
                            return int(float(avail[:-1]) * 1024 * 1024 * 1024)
                        elif avail.endswith('M'):
                            return int(float(avail[:-1]) * 1024 * 1024)
                        elif avail.endswith('K'):
                            return int(float(avail[:-1]) * 1024)
                        else:
                            try:
                                return int(avail)
                            except ValueError:
                                return 0
            return 0
        except Exception as e:
            self.logger.warning(f"Failed to get storage info: {str(e)}")
            return 0

    async def _get_battery_info(self) -> Tuple[int, bool]:
        """Get battery level and charging status"""
        try:
            output = self.device.shell("dumpsys battery")
            level = 0
            charging = False
            
            for line in output.splitlines():
                if "level:" in line:
                    try:
                        level = int(line.split(":")[-1].strip())
                    except ValueError:
                        pass
                elif "plugged:" in line:
                    charging = line.split(":")[-1].strip() != "0"
                    
            return level, charging
        except Exception as e:
            self.logger.warning(f"Failed to get battery info: {str(e)}")
            return 0, False

    async def _get_wifi_mac(self) -> str:
        """Get WiFi MAC address"""
        try:
            output = self.device.shell("ip addr show wlan0")
            for line in output.splitlines():
                if "link/ether" in line:
                    parts = line.strip().split()
                    if len(parts) >= 2:
                        return parts[1]
            return None
        except Exception:
            return None

    def _parse_memory_size(self, size_str: str) -> int:
        """Parse memory size string to bytes"""
        try:
            if 'GB' in size_str:
                return int(float(size_str.replace('GB', '')) * 1024 * 1024 * 1024)
            elif 'MB' in size_str:
                return int(float(size_str.replace('MB', '')) * 1024 * 1024)
            elif 'KB' in size_str:
                return int(float(size_str.replace('KB', '')) * 1024)
            else:
                return int(size_str)
        except (ValueError, TypeError):
            return 0

    async def _validate_backup_environment(self):
        """Validate backup environment before starting"""
        # Check storage space
        free_space = await self._get_storage_free()
        total_space = free_space  # This is approximate since we don't have total space info
        
        if total_space > 0:
            free_percent = (free_space / total_space) * 100
            if free_percent < self.config.min_free_space_percent:
                self.logger.warning(f"Low storage space: {free_space/(1024*1024*1024):.2f}GB free "
                                   f"({free_percent:.1f}%). Backup might fail.")
        elif free_space < 5 * 1024 * 1024 * 1024:  # 5GB minimum
            self.logger.warning(f"Low storage space: {free_space/(1024*1024*1024):.2f}GB free. Backup might fail.")
        
        # Check battery level if not charging
        if not self.device_info.battery_charging and self.device_info.battery_level < 30:
            self.logger.warning(f"Low battery ({self.device_info.battery_level}%) and not charging. Backup may fail.")
            if self.device_info.battery_level < 15:
                raise CriticalError(f"Battery level too low ({self.device_info.battery_level}%). "
                                  "Please charge your device before backing up.")
        
        # Check local disk space
        local_disk = psutil.disk_usage(self.backup_root)
        if local_disk.free < 10 * 1024 * 1024 * 1024:  # 10GB minimum
            raise CriticalError(f"Insufficient local disk space: {local_disk.free/(1024*1024*1024):.2f}GB free. "
                               "At least 10GB recommended.")
                               
        # Check device connectivity
        try:
            self.device.shell("echo test")
        except Exception as e:
            raise CriticalError(f"Device connection test failed: {str(e)}")

    async def _execute_adb_command(self, command: str, as_root: bool = False) -> str:
        """Execute ADB command with optional root privileges"""
        try:
            if as_root and self.device_info.is_rooted:
                command = f"su -c '{command}'"
            return self.device.shell(command)
        except Exception as e:
            self.logger.error(f"ADB command failed: {str(e)}, Command: {command}")
            raise RecoverableError(f"ADB command failed: {str(e)}")

    async def backup(self) -> Path:
        """Perform complete device backup with error recovery"""
        try:
            await self._init_device()
            self._start_time = datetime.now()
            self._backup_dir = self._create_backup_dir()
            
            self.logger.info(f"Starting backup to {self._backup_dir}")
            await self._save_device_info(self._backup_dir)
            
            # Create necessary subdirectories
            os.makedirs(self._backup_dir / "apps", exist_ok=True)
            os.makedirs(self._backup_dir / "data", exist_ok=True)
            os.makedirs(self._backup_dir / "system", exist_ok=True)
            
            # Load previous progress if exists
            await self._load_progress(self._backup_dir)
            
            # Get package list
            packages = await self._get_packages()
            self._package_count = len(packages)
            self._progress['total'] = self._package_count
            
            # Backup system data first
            if self.device_info.is_rooted:
                await self._backup_system_data(self._backup_dir / "system")
            
            # Back up apps and app data
            for i, pkg in enumerate(packages):
                try:
                    self.logger.info(f"Processing package {i+1}/{self._package_count}: {pkg['package']}")
                    await self._backup_package(pkg, self._backup_dir)
                    self._progress['completed'] += 1
                    
                    # Save progress periodically (every 10 packages)
                    if i % 10 == 0:
                        await self._save_progress(self._backup_dir)
                        self._update_progress(i, self._package_count, f"Backing up {pkg['package']}")
                except Exception as e:
                    self._progress['errors'].append(f"{pkg['package']}: {str(e)}")
                    self.logger.error(f"Failed to backup package {pkg['package']}: {str(e)}")
            
            # Handle backups that need root access
            if self.device_info.is_rooted:
                await self._backup_ssaid(self._backup_dir / "system")
                await self._backup_system_apps_whitelist(self._backup_dir / "system" / "whitelist")
            
            # Finalize backup
            final_path = await self._finalize_backup(self._backup_dir)
            self.logger.info(f"Backup completed successfully: {final_path}")
            
            # Cloud backup
            if self.cloud:
                metadata = {
                    'device_model': self.device_info.model,
                    'android_version': self.device_info.android_version,
                    'backup_size': os.path.getsize(final_path),
                    'encrypted': self.config.encryption_enabled,
                    'package_count': self._package_count,
                    'timestamp': datetime.now().isoformat(),
                    'device_info': asdict(self.device_info)
                }
                self.logger.info("Uploading backup to cloud storage...")
                await self.cloud.upload_backup(final_path, metadata)

            return final_path
        except Exception as e:
            if self._backup_dir:
                await self._save_progress(self._backup_dir)
            self.logger.error(f"Backup failed: {str(e)}")
            raise

    def _create_backup_dir(self) -> Path:
        """Create unique backup directory"""
        # Ensure backup root exists
        os.makedirs(self.backup_root, exist_ok=True)
        
        # Create unique timestamped directory
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        device_model = self.device_info.model if self.device_info else "unknown"
        backup_dir = self.backup_root / f"{device_model}_{timestamp}"
        os.makedirs(backup_dir, exist_ok=True)
        return backup_dir

    def _update_progress(self, current: int, total: int, message: str = ""):
        """Update progress with percentage and ETA"""
        if total <= 0:
            return
            
        percent = min(100, int(current * 100 / total))
        
        if self._start_time:
            elapsed = (datetime.now() - self._start_time).total_seconds()
            if current > 0 and elapsed > 0:
                rate = current / elapsed
                eta_seconds = (total - current) / rate if rate > 0 else 0
                eta = str(timedelta(seconds=int(eta_seconds)))
            else:
                eta = "Calculating..."
        else:
            eta = "Unknown"
        
        if message:
            progress_text = f"[{percent}%] {current}/{total} - {message} (ETA: {eta})"
        else:
            progress_text = f"[{percent}%] {current}/{total} (ETA: {eta})"
            
        self.logger.info(progress_text)

    async def _backup_package(self, pkg: Dict, backup_dir: Path):
        """Backup individual package with comprehensive data handling"""
        package_name = pkg['package']
        
        # Skip already backed up packages
        if package_name in self._progress.get('completed_packages', []):
            self.logger.info(f"Package {package_name} already backed up, skipping...")
            return
        
        try:
            # Create package-specific directory
            package_dir = backup_dir / "apps" / package_name
            os.makedirs(package_dir, exist_ok=True)
            
            # Get app details
            app_info = await self._get_app_info(package_name)
            
            # Save app info
            async with aiofiles.open(package_dir / "info.json", 'w') as f:
                await f.write(json.dumps(app_info, indent=2))
            
            # Backup APK
            await self._backup_apk(package_name, package_dir)
            
            # Backup app permissions if rooted
            if self.device_info.is_rooted:
                await self._backup_app_permissions(package_name, package_dir)
                await self._backup_app_data(package_name, backup_dir / "data")
            
            # Add to completed packages
            if 'completed_packages' not in self._progress:
                self._progress['completed_packages'] = []
            self._progress['completed_packages'].append(package_name)
            
        except Exception as e:
            self.logger.error(f"Failed to backup package {package_name}: {str(e)}")
            self._progress['errors'].append(f"{package_name}: {str(e)}")
            raise RecoverableError(f"Package backup failed: {str(e)}")

    async def _get_app_info(self, package_name: str) -> Dict:
        """Get detailed app information"""
        try:
            # Execute dumpsys to get package info
            output = await self._execute_adb_command(f"dumpsys package {package_name}")
            
            # Parse the output
            info = {
                'package': package_name,
                'version_name': None,
                'version_code': None,
                'first_install_time': None,
                'last_update_time': None,
                'uid': None
            }
            
            # Extract version info
            version_match = re.search(r'versionName=([^\s]+)', output)
            if version_match:
                info['version_name'] = version_match.group(1)
                
            version_code_match = re.search(r'versionCode=(\d+)', output)
            if version_code_match:
                info['version_code'] = int(version_code_match.group(1))
                
            # Extract install times
            first_install_match = re.search(r'firstInstallTime=([^\n]+)', output)
            if first_install_match:
                info['first_install_time'] = first_install_match.group(1)
                
            update_match = re.search(r'lastUpdateTime=([^\n]+)', output)
            if update_match:
                info['last_update_time'] = update_match.group(1)
                
            # Extract UID
            uid_match = re.search(r'userId=(\d+)', output)
            if uid_match:
                info['uid'] = uid_match.group(1)
                
            return info
        except Exception as e:
            self.logger.error(f"Failed to get info for {package_name}: {str(e)}")
            return {'package': package_name}

    async def _get_storage_free(self) -> int:
        """Get available storage space on device"""
        try:
            output = await self.device.shell("df -h /data")
            for line in output.strip().split('\n'):
                if '/data' in line:
                    parts = line.split()
                    if len(parts) >= 4:
                        # Convert human-readable size to bytes
                        size_str = parts[3]
                        if 'G' in size_str:
                            return int(float(size_str.replace('G', '')) * 1024 * 1024 * 1024)
                        elif 'M' in size_str:
                            return int(float(size_str.replace('M', '')) * 1024 * 1024)
                        elif 'K' in size_str:
                            return int(float(size_str.replace('K', '')) * 1024)
                        else:
                            return int(size_str)
            return 0
        except Exception:
            return 0

    async def _execute_adb_command(self, command: str, as_root: bool = False) -> str:
        """Execute ADB command with optional root privileges"""
        if as_root and self.device_info.is_rooted:
            command = f"su -c '{command}'"
        return await self.device.shell(command)

    async def _encrypt_file(self, source_path: Path, dest_path: Path):
        """Encrypt file using Fernet encryption"""
        if not self.fernet:
            shutil.copy(source_path, dest_path)
            return
            
        async with aiofiles.open(source_path, 'rb') as src:
            data = await src.read()
            
        encrypted_data = self.fernet.encrypt(data)
        
        async with aiofiles.open(dest_path, 'wb') as dest:
            await dest.write(encrypted_data)

    async def _decrypt_file(self, source_path: Path, dest_path: Path):
        """Decrypt file using Fernet encryption"""
        if not self.fernet:
            shutil.copy(source_path, dest_path)
            return
            
        async with aiofiles.open(source_path, 'rb') as src:
            data = await src.read()
            
        decrypted_data = self.fernet.decrypt(data)
        
        async with aiofiles.open(dest_path, 'wb') as dest:
            await dest.write(decrypted_data)

    async def backup_app_permissions(self, package_name: str, backup_dir: Path):
        """Back up runtime permissions similar to YAWAsau's script"""
        if not self.device_info.is_rooted:
            return
            
        try:
            # Get package UID
            uid_cmd = f"dumpsys package {package_name} | grep userId="
            uid_output = await self._execute_adb_command(uid_cmd)
            uid = uid_output.split('=')[1].strip()
            
            # Get permissions
            perm_cmd = f"dumpsys package {package_name} | grep -A20 'runtime permissions:'"
            permissions = await self._execute_adb_command(perm_cmd)
            
            # Save permissions
            perm_path = backup_dir / f"{package_name}.permissions"
            async with aiofiles.open(perm_path, 'w') as f:
                await f.write(f"UID:{uid}\n{permissions}")
                
            self.logger.info(f"Backed up permissions for {package_name}")
        except Exception as e:
            self.logger.error(f"Failed to backup permissions for {package_name}: {str(e)}")

    async def _backup_app_data(self, pkg: Dict, backup_dir: Path):
        """Enhanced app data backup using root access"""
        if not self.device_info.is_rooted:
            return
            
        try:
            package = pkg['package']
            data_path = f"/data/data/{package}"
            
            # Create directory structure
            os.makedirs(backup_dir / package, exist_ok=True)
            
            # List directories to backup
            dirs_cmd = f"find {data_path} -maxdepth 1 -type d | grep -v '^{data_path}$'"
            dirs_output = await self._execute_adb_command(dirs_cmd, as_root=True)
            
            for dir_path in dirs_output.splitlines():
                dir_name = os.path.basename(dir_path)
                
                # Skip excluded directories
                if dir_name in self.config.exclude_dirs:
                    continue
                    
                # Create tar archive of the directory
                tar_cmd = f"tar -c -C {data_path} {dir_name} | base64"
                tar_output = await self._execute_adb_command(tar_cmd, as_root=True)
                
                if tar_output:
                    # Decode and save
                    tar_path = backup_dir / package / f"{dir_name}.tar"
                    decoded_data = base64.b64decode(tar_output)
                    
                    async with aiofiles.open(tar_path, 'wb') as f:
                        await f.write(decoded_data)
                    
            self.logger.info(f"App data for {package} backed up successfully")
        except Exception as e:
            self.logger.error(f"Failed to backup app data for {package}: {str(e)}")
            self._progress['errors'].append(f"{package}: {str(e)}")

    async def _backup_ssaid(self, backup_dir: Path):
        """Backup SSAID settings (important for apps like LINE)"""
        if not self.device_info.is_rooted:
            return
            
        try:
            ssaid_path = "/data/system/users/0/settings_ssaid.xml"
            check_cmd = f"[ -f {ssaid_path} ] && echo 'exists' || echo 'not found'"
            result = await self._execute_adb_command(check_cmd, as_root=True)
            
            if "exists" in result:
                # Pull SSAID data
                cat_cmd = f"cat {ssaid_path} | base64"
                ssaid_data = await self._execute_adb_command(cat_cmd, as_root=True)
                
                if ssaid_data:
                    dest_path = backup_dir / "settings_ssaid.xml"
                    decoded_data = base64.b64decode(ssaid_data)
                    
                    async with aiofiles.open(dest_path, 'wb') as f:
                        await f.write(decoded_data)
                        
                    self.logger.info("SSAID data backed up successfully")
            else:
                self.logger.info("SSAID file not found, skipping")
        except Exception as e:
            self.logger.error(f"Failed to backup SSAID: {str(e)}")

    async def backup_system_apps_whitelist(self, backup_dir: Path):
        """Back up system apps whitelist, similar to YAWAsau's script"""
        # Create whitelist directory
        whitelist_dir = backup_dir / "system_whitelist"
        os.makedirs(whitelist_dir, exist_ok=True)
        
        # Common important system apps
        system_apps = [
            "com.google.android.gms",
            "com.google.android.gsf",
            "com.android.vending"
        ]
        
        for app in system_apps:
            try:
                # Check if system app
                cmd = f"pm list packages -s | grep {app}"
                result = await self.device.shell(cmd)
                
                if app in result:
                    # Get app info
                    info_cmd = f"dumpsys package {app} | grep -E 'versionName|firstInstallTime|lastUpdateTime'"
                    info = await self.device.shell(info_cmd)
                    
                    # Save app info
                    async with aiofiles.open(whitelist_dir / f"{app}.info", "w") as f:
                        await f.write(info)
                        
                    # Backup APK if needed
                    await self._backup_apk({"package": app}, whitelist_dir)
                    
                    self.logger.info(f"System app {app} added to whitelist")
            except Exception as e:
                self.logger.warning(f"Failed to process system app {app}: {str(e)}")

    async def _validate_backup_environment(self):
        """Validate backup environment before starting"""
        # Check storage space
        free_space = await self._get_storage_free()
        required_space = 5 * 1024 * 1024 * 1024  # 5GB minimum
        
        if free_space < required_space:
            raise CriticalError(f"Insufficient storage space: {free_space/(1024*1024*1024):.2f}GB available, 5GB recommended")
        
        # Check battery level if on battery
        battery_cmd = "dumpsys battery | grep level"
        battery_output = await self.device.shell(battery_cmd)
        
        try:
            battery_level = int(battery_output.split(':')[1].strip())
            charging_cmd = "dumpsys battery | grep powered"
            charging_output = await self.device.shell(charging_cmd)
            is_charging = "true" in charging_output.lower()
            
            if battery_level < 30 and not is_charging:
                self.logger.warning(f"Low battery ({battery_level}%) and not charging. Backup may fail.")
        except Exception:
            self.logger.warning("Could not determine battery status")

    def update_progress(self, current: int, total: int, message: str = ""):
        """Update progress with percentage and ETA"""
        if total <= 0:
            return
            
        percent = min(100, int(current * 100 / total))
        
        if self._start_time:
            elapsed = (datetime.now() - self._start_time).total_seconds()
            if current > 0 and elapsed > 0:
                rate = current / elapsed
                eta_seconds = (total - current) / rate if rate > 0 else 0
                eta = str(datetime.timedelta(seconds=int(eta_seconds)))
            else:
                eta = "Calculating..."
        else:
            eta = "Unknown"
        
        if message:
            progress_text = f"[{percent}%] {current}/{total} - {message} (ETA: {eta})"
        else:
            progress_text = f"[{percent}%] {current}/{total} (ETA: {eta})"
            
        self.logger.info(progress_text)

    async def _create_backup_dir(self) -> Path:
        """Create a uniquely named backup directory"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        device_model = self.device_info.model.replace(" ", "_")
        backup_dir = self.backup_root / f"{device_model}_{timestamp}"
        
        os.makedirs(backup_dir, exist_ok=True)
        os.makedirs(backup_dir / "apps", exist_ok=True)
        os.makedirs(backup_dir / "data", exist_ok=True)
        os.makedirs(backup_dir / "system", exist_ok=True)
        
        return backup_dir
        
    async def _restore_app_data(self, package: str, data_dir: Path):
        """Restore app data from backup"""
        if not self.device_info.is_rooted:
            self.logger.warning(f"Root access required to restore data for {package}")
            return
            
        try:
            # Ensure app data directory exists on device
            app_data_path = f"/data/data/{package}"
            check_cmd = f"[ -d {app_data_path} ] && echo 'exists'"
            result = await self._execute_adb_command(check_cmd, as_root=True)
            
            if "exists" not in result:
                self.logger.warning(f"App data directory for {package} not found on device")
                return
                
            # Process each data tar file
            for tar_file in data_dir.glob("*.tar"):
                dir_name = tar_file.stem
                
                # Skip excluded directories
                if dir_name in self.config.exclude_dirs:
                    continue
                    
                # Clear existing directory contents
                clear_cmd = f"rm -rf {app_data_path}/{dir_name}/*"
                await self._execute_adb_command(clear_cmd, as_root=True)
                
                # Create temp file on device
                temp_tar = f"/data/local/tmp/{package}_{dir_name}.tar"
                
                # Read and encode the tar file
                async with aiofiles.open(tar_file, 'rb') as f:
                    tar_data = await f.read()
                encoded_data = base64.b64encode(tar_data).decode('utf-8')
                
                # Write encoded data to device in chunks
                chunk_size = 4096
                chunks = [encoded_data[i:i+chunk_size] for i in range(0, len(encoded_data), chunk_size)]
                
                # Clear any existing file
                await self._execute_adb_command(f"echo '' > {temp_tar}", as_root=True)
                
                # Write data in chunks
                for chunk in chunks:
                    append_cmd = f"echo '{chunk}' | base64 -d >> {temp_tar}"
                    await self._execute_adb_command(append_cmd, as_root=True)
                
                # Extract tar file
                extract_cmd = f"tar -xf {temp_tar} -C {app_data_path}"
                await self._execute_adb_command(extract_cmd, as_root=True)
                
                # Fix permissions
                chown_cmd = f"chown -R {self._get_app_uid(package)} {app_data_path}/{dir_name}"
                await self._execute_adb_command(chown_cmd, as_root=True)
                
                # Clean up
                await self._execute_adb_command(f"rm {temp_tar}", as_root=True)
                
            self.logger.info(f"Restored data for {package} successfully")
        except Exception as e:
            self.logger.error(f"Failed to restore data for {package}: {str(e)}")
            self._progress['errors'].append(f"{package}: {str(e)}")
            
    async def _get_app_uid(self, package: str) -> str:
        """Get the UID for an app package"""
        cmd = f"dumpsys package {package} | grep userId="
        result = await self._execute_adb_command(cmd)
        match = re.search(r'userId=(\d+)', result)
        if match:
            return f"{match.group(1)}:{match.group(1)}"
        return "1000:1000"  # Default to system UID if not found

    async def _restore_permissions(self, package: str, perm_file: Path):
        """Restore app permissions"""
        if not self.device_info.is_rooted:
            self.logger.warning(f"Root access required to restore permissions for {package}")
            return
            
        try:
            async with aiofiles.open(perm_file, 'r') as f:
                content = await f.read()
                
            # Extract UID
            uid_match = re.search(r'UID:(\d+)', content)
            if not uid_match:
                self.logger.error(f"Failed to find UID in permission file for {package}")
                return
                
            uid = uid_match.group(1)
            
            # Parse permissions
            for line in content.splitlines():
                perm_match = re.search(r'([a-zA-Z0-9._]+): granted=([a-z]+)', line)
                if perm_match:
                    permission = perm_match.group(1)
                    granted = perm_match.group(2) == "true"
                    
                    # Grant or revoke permission
                    action = "grant" if granted else "revoke"
                    cmd = f"pm {action} {package} {permission}"
                    await self._execute_adb_command(cmd, as_root=True)
                    
            self.logger.info(f"Restored permissions for {package}")
        except Exception as e:
            self.logger.error(f"Failed to restore permissions for {package}: {str(e)}")
    
    async def _restore_ssaid(self, ssaid_file: Path):
        """Restore SSAID settings"""
        if not self.device_info.is_rooted:
            self.logger.warning("Root access required to restore SSAID")
            return
            
        try:
            # Check if file exists
            if not ssaid_file.exists():
                self.logger.warning("SSAID file not found in backup")
                return
                
            # Path on device
            ssaid_path = "/data/system/users/0/settings_ssaid.xml"
            
            # Read the file
            async with aiofiles.open(ssaid_file, 'rb') as f:
                ssaid_data = await f.read()
                
            # Encode file content
            encoded_data = base64.b64encode(ssaid_data).decode('utf-8')
            
            # Create temp file on device
            temp_file = "/data/local/tmp/settings_ssaid.xml"
            
            # Write data in chunks
            chunk_size = 4096
            chunks = [encoded_data[i:i+chunk_size] for i in range(0, len(encoded_data), chunk_size)]
            
            # Clear any existing file
            await self._execute_adb_command(f"echo '' > {temp_file}", as_root=True)
            
            # Write data in chunks
            for chunk in chunks:
                append_cmd = f"echo '{chunk}' | base64 -d >> {temp_file}"
                await self._execute_adb_command(append_cmd, as_root=True)
                
            # Move file to correct location
            move_cmd = f"cp {temp_file} {ssaid_path} && chmod 660 {ssaid_path} && chown system:system {ssaid_path}"
            await self._execute_adb_command(move_cmd, as_root=True)
            
            # Clean up
            await self._execute_adb_command(f"rm {temp_file}", as_root=True)
            
            self.logger.info("SSAID restored successfully")
        except Exception as e:
            self.logger.error(f"Failed to restore SSAID: {str(e)}")
    
    async def install_apk(self, apk_path: Path) -> bool:
        """Install APK file"""
        try:
            # Check if file exists
            if not apk_path.exists():
                self.logger.error(f"APK file not found: {apk_path}")
                return False
                
            # Install APK
            cmd = f"pm install -r {apk_path}"
            if self.device_info.is_rooted:
                cmd = f"su -c '{cmd}'"
                
            result = await self.device.shell(cmd)
            
            if "Success" in result:
                return True
            else:
                self.logger.error(f"Failed to install APK: {result}")
                return False
        except Exception as e:
            self.logger.error(f"Error installing APK: {str(e)}")
            return False
            
    async def _verify_backup_integrity(self, backup_dir: Path) -> bool:
        """Verify backup integrity by checking hash values"""
        manifest_path = backup_dir / "manifest.json"
        try:
            if not manifest_path.exists():
                self.logger.error("Backup manifest not found")
                return False
                
            # Load manifest
            async with aiofiles.open(manifest_path, 'r') as f:
                manifest = json.loads(await f.read())
                
            # Verify each file
            total_files = len(manifest['files'])
            verified_files = 0
            
            for file_info in manifest['files']:
                rel_path = file_info['path']
                expected_hash = file_info['hash']
                
                file_path = backup_dir / rel_path
                if not file_path.exists():
                    self.logger.error(f"Missing file: {rel_path}")
                    continue
                    
                # Calculate hash
                hash_obj = hashlib.md5()
                async with aiofiles.open(file_path, 'rb') as f:
                    chunk = await f.read(4096)
                    while chunk:
                        hash_obj.update(chunk)
                        chunk = await f.read(4096)
                        
                actual_hash = hash_obj.hexdigest()
                
                if actual_hash != expected_hash:
                    self.logger.error(f"Hash mismatch for {rel_path}")
                else:
                    verified_files += 1
                    
            integrity_percentage = (verified_files / total_files) * 100 if total_files > 0 else 0
            
            self.logger.info(f"Backup integrity: {integrity_percentage:.2f}% ({verified_files}/{total_files} files verified)")
            
            return integrity_percentage > 95  # Consider backup valid if >95% of files are verified
            
        except Exception as e:
            self.logger.error(f"Error verifying backup integrity: {str(e)}")
            return False
    
    async def list_backups(self) -> List[Dict]:
        """List all available backups with their metadata"""
        backups = []
        
        try:
            # List all backup directories
            for backup_dir in self.backup_root.glob("*_*"):
                if not backup_dir.is_dir():
                    continue
                    
                try:
                    # Load metadata
                    metadata_path = backup_dir / "metadata.json"
                    if metadata_path.exists():
                        async with aiofiles.open(metadata_path, 'r') as f:
                            metadata = json.loads(await f.read())
                    else:
                        # Create basic metadata from directory name
                        parts = backup_dir.name.split('_')
                        if len(parts) >= 3:
                            device = parts[0]
                            date_str = parts[1]
                            time_str = parts[2]
                            timestamp = f"{date_str} {time_str.replace('_', ':')}"
                            metadata = {
                                "device_model": device,
                                "timestamp": timestamp,
                                "app_count": 0,
                                "status": "unknown"
                            }
                        else:
                            metadata = {
                                "device_model": "Unknown",
                                "timestamp": backup_dir.name,
                                "app_count": 0,
                                "status": "unknown"
                            }
                            
                    # Count apps if not in metadata
                    if "app_count" not in metadata or metadata["app_count"] == 0:
                        apps_dir = backup_dir / "apps"
                        if apps_dir.exists():
                            metadata["app_count"] = len(list(apps_dir.glob("*.apk")))
                            
                    # Add size information
                    total_size = sum(f.stat().st_size for f in backup_dir.glob('**/*') if f.is_file())
                    metadata["size_bytes"] = total_size
                    metadata["size_human"] = self._human_readable_size(total_size)
                    
                    # Add directory path
                    metadata["path"] = str(backup_dir)
                    
                    backups.append(metadata)
                except Exception as e:
                    self.logger.error(f"Error reading backup metadata for {backup_dir}: {str(e)}")
                
        except Exception as e:
            self.logger.error(f"Error listing backups: {str(e)}")
            
        # Sort backups by timestamp (newest first)
        backups.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
        
        return backups
    
    def _human_readable_size(self, size_bytes: int) -> str:
        """Convert bytes to human-readable size"""
        if size_bytes < 1024:
            return f"{size_bytes} B"
        elif size_bytes < 1024 * 1024:
            return f"{size_bytes/1024:.2f} KB"
        elif size_bytes < 1024 * 1024 * 1024:
            return f"{size_bytes/(1024*1024):.2f} MB"
        else:
            return f"{size_bytes/(1024*1024*1024):.2f} GB"
    
    async def delete_backup(self, backup_path: str) -> bool:
        """Delete a backup by path"""
        try:
            backup_dir = Path(backup_path)
            if not backup_dir.exists() or not backup_dir.is_dir():
                self.logger.error(f"Backup directory not found: {backup_path}")
                return False
                
            # Remove the directory and all its contents
            shutil.rmtree(backup_dir)
            
            self.logger.info(f"Backup deleted: {backup_path}")
            return True
        except Exception as e:
            self.logger.error(f"Failed to delete backup: {str(e)}")
            return False
    
    async def cloud_backup(self, backup_path: Path) -> bool:
        """Upload backup to cloud storage"""
        if not self.cloud_manager:
            self.logger.error("Cloud manager not configured")
            return False
            
        try:
            # Check if backup exists
            if not backup_path.exists():
                self.logger.error(f"Backup not found: {backup_path}")
                return False
                
            # Load metadata
            metadata_path = backup_path / "metadata.json"
            if metadata_path.exists():
                async with aiofiles.open(metadata_path, 'r') as f:
                    metadata = json.loads(await f.read())
            else:
                metadata = {
                    "device_model": "Unknown",
                    "timestamp": datetime.now().isoformat()
                }
                
            # Create archive for upload
            archive_path = Path(f"{backup_path}.zip")
            
            self.logger.info(f"Creating archive for cloud backup: {archive_path}")
            
            # Create zip archive
            with zipfile.ZipFile(archive_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
                for root, _, files in os.walk(backup_path):
                    for file in files:
                        file_path = Path(root) / file
                        rel_path = file_path.relative_to(backup_path)
                        zipf.write(file_path, rel_path)
            
            # Upload to cloud
            self.logger.info("Uploading backup to cloud storage...")
            await self.cloud_manager.upload_backup(archive_path, metadata)
            
            # Clean up
            os.remove(archive_path)
            
            self.logger.info("Backup uploaded to cloud successfully")
            return True
        except Exception as e:
            self.logger.error(f"Failed to upload backup to cloud: {str(e)}")
            return False

    async def compare_backups(self, backup1_path: Path, backup2_path: Path) -> Dict:
        """Compare two backups and return differences"""
        try:
            result = {
                "added_apps": [],
                "removed_apps": [],
                "changed_apps": [],
                "summary": {}
            }
            
            # Load manifests
            manifest1_path = backup1_path / "manifest.json"
            manifest2_path = backup2_path / "manifest.json"
            
            if not manifest1_path.exists() or not manifest2_path.exists():
                raise FileNotFoundError("Manifest files not found in one or both backups")
                
            async with aiofiles.open(manifest1_path, 'r') as f1:
                manifest1 = json.loads(await f1.read())
                
            async with aiofiles.open(manifest2_path, 'r') as f2:
                manifest2 = json.loads(await f2.read())
                
            # Extract app lists
            apps1 = {app['package']: app for app in manifest1.get('apps', [])}
            apps2 = {app['package']: app for app in manifest2.get('apps', [])}
            
            # Find added and removed apps
            result["added_apps"] = [pkg for pkg in apps2 if pkg not in apps1]
            result["removed_apps"] = [pkg for pkg in apps1 if pkg not in apps2]
            
            # Find changed apps (version differences)
            for pkg, app2 in apps2.items():
                if pkg in apps1:
                    app1 = apps1[pkg]
                    if app1.get('version_code') != app2.get('version_code'):
                        result["changed_apps"].append({
                            "package": pkg,
                            "old_version": app1.get('version_name', 'unknown'),
                            "new_version": app2.get('version_name', 'unknown')
                        })
            
            # Summary
            result["summary"] = {
                "backup1_date": manifest1.get('timestamp', 'unknown'),
                "backup2_date": manifest2.get('timestamp', 'unknown'),
                "backup1_app_count": len(apps1),
                "backup2_app_count": len(apps2),
                "added_count": len(result["added_apps"]),
                "removed_count": len(result["removed_apps"]),
                "changed_count": len(result["changed_apps"])
            }
            
            return result
            
        except Exception as e:
            self.logger.error(f"Failed to compare backups: {str(e)}")
            return {"error": str(e)}
            
    async def create_incremental_backup(self, base_backup_path: Path) -> Path:
        """Create an incremental backup based on a previous full backup"""
        try:
            # Verify base backup exists
            if not base_backup_path.exists():
                raise FileNotFoundError(f"Base backup not found: {base_backup_path}")
                
            # Load base manifest
            base_manifest_path = base_backup_path / "manifest.json"
            if not base_manifest_path.exists():
                raise FileNotFoundError("Base backup manifest not found")
                
            async with aiofiles.open(base_manifest_path, 'r') as f:
                base_manifest = json.loads(await f.read())
            
            # Create incremental backup directory
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            device_model = self.device_info.model.replace(" ", "_")
            incremental_dir = self.backup_root / f"{device_model}_incr_{timestamp}"
            
            os.makedirs(incremental_dir, exist_ok=True)
            os.makedirs(incremental_dir / "apps", exist_ok=True)
            os.makedirs(incremental_dir / "data", exist_ok=True)
            os.makedirs(incremental_dir / "system", exist_ok=True)
            
            # Get current packages
            current_packages = await self._get_packages()
            
            # Extract base package info
            base_packages = {app['package']: app for app in base_manifest.get('apps', [])}
            
            # Identify changes
            changed_packages = []
            new_packages = []
            
            for pkg_info in current_packages:
                pkg = pkg_info['package']
                # Skip system apps unless explicitly requested
                if pkg_info.get('system', False) and pkg not in self.config.system_whitelist:
                    continue
                    
                app_info = await self._get_app_info(pkg)
                
                if pkg in base_packages:
                    # App exists in base backup, check if changed
                    base_app = base_packages[pkg]
                    if str(app_info.get('version_code')) != str(base_app.get('version_code')):
                        self.logger.info(f"App updated: {pkg} (version changed from {base_app.get('version_name')} to {app_info.get('version_name')})")
                        changed_packages.append(pkg_info)
                else:
                    # New app
                    self.logger.info(f"New app detected: {pkg}")
                    new_packages.append(pkg_info)
            
            # Backup changed and new apps
            packages_to_backup = changed_packages + new_packages
            total = len(packages_to_backup)
            self.logger.info(f"Found {len(changed_packages)} changed apps and {len(new_packages)} new apps")
            
            # Create incremental manifest
            incremental_manifest = {
                "type": "incremental",
                "base_backup": str(base_backup_path.name),
                "timestamp": datetime.now().isoformat(),
                "device": self.device_info.__dict__,
                "apps": [],
                "changed_apps": len(changed_packages),
                "new_apps": len(new_packages),
                "files": []
            }
            
            # Backup changed/new apps
            for i, pkg_info in enumerate(packages_to_backup):
                self.update_progress(i + 1, total, f"Backing up {pkg_info['package']}")
                
                # Backup the app
                await self._backup_package(pkg_info, incremental_dir)
                
                # Add to manifest
                app_info = await self._get_app_info(pkg_info['package'])
                incremental_manifest["apps"].append(app_info)
            
            # Save incremental manifest
            async with aiofiles.open(incremental_dir / "incremental_manifest.json", 'w') as f:
                await f.write(json.dumps(incremental_manifest, indent=2))
            
            # Create reference to base backup
            async with aiofiles.open(incremental_dir / "base_backup.txt", 'w') as f:
                await f.write(str(base_backup_path))
                
            self.logger.info(f"Incremental backup completed: {incremental_dir}")
            return incremental_dir
            
        except Exception as e:
            self.logger.error(f"Failed to create incremental backup: {str(e)}")
            raise
            
    async def restore_incremental_backup(self, incremental_backup_path: Path) -> bool:
        """Restore from an incremental backup"""
        try:
            # Check if it's an incremental backup
            incr_manifest_path = incremental_backup_path / "incremental_manifest.json"
            base_ref_path = incremental_backup_path / "base_backup.txt"
            
            if not incr_manifest_path.exists() or not base_ref_path.exists():
                self.logger.error("Not a valid incremental backup")
                return False
                
            # Get base backup path
            async with aiofiles.open(base_ref_path, 'r') as f:
                base_path_str = await f.read()
                base_backup_path = Path(base_path_str.strip())
                
            if not base_backup_path.exists():
                self.logger.error(f"Base backup not found: {base_backup_path}")
                return False
                
            # Load incremental manifest
            async with aiofiles.open(incr_manifest_path, 'r') as f:
                incr_manifest = json.loads(await f.read())
                
            # Restore apps from incremental backup
            self.logger.info(f"Restoring {len(incr_manifest.get('apps', []))} apps from incremental backup")
            
            # Restore changed/new apps
            total = len(incr_manifest.get('apps', []))
            for i, app_info in enumerate(incr_manifest.get('apps', [])):
                package = app_info['package']
                self.update_progress(i + 1, total, f"Restoring {package}")
                
                # Install APK
                apk_path = incremental_backup_path / "apps" / f"{package}.apk"
                if apk_path.exists():
                    await self.install_apk(apk_path)
                    
                # Restore app data
                data_dir = incremental_backup_path / "data" / package
                if data_dir.exists():
                    await self._restore_app_data(package, data_dir)
                    
                # Restore permissions
                perm_file = incremental_backup_path / f"{package}.permissions"
                if perm_file.exists():
                    await self._restore_permissions(package, perm_file)
                    
            self.logger.info("Incremental backup restored successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to restore incremental backup: {str(e)}")
            return False
            
    async def optimize_backup_size(self, backup_path: Path) -> int:
        """Optimize backup size by removing unnecessary files"""
        try:
            total_saved = 0
            
            # Look for large cache directories in app data
            for app_data_dir in (backup_path / "data").glob("*"):
                if not app_data_dir.is_dir():
                    continue
                    
                # Common directories to clean
                dirs_to_clean = ["cache", "code_cache", "no_backup"]
                
                for cache_dir in dirs_to_clean:
                    cache_path = app_data_dir / cache_dir
                    if cache_path.exists() and cache_path.is_dir():
                        # Calculate size
                        size = sum(f.stat().st_size for f in cache_path.glob('**/*') if f.is_file())
                        
                        # Remove directory
                        shutil.rmtree(cache_path)
                        
                        # Create placeholder
                        os.makedirs(cache_path, exist_ok=True)
                        
                        total_saved += size
                        self.logger.info(f"Cleaned {cache_dir} in {app_data_dir.name}, saved {self._human_readable_size(size)}")
            
            # Remove duplicate files (based on hash)
            hash_map = {}
            dupes_found = 0
            dupes_size = 0
            
            for file_path in backup_path.glob('**/*'):
                if not file_path.is_file() or file_path.suffix == '.json':
                    continue
                    
                # Calculate file hash
                hash_obj = hashlib.md5()
                with open(file_path, 'rb') as f:
                    chunk = f.read(4096)
                    while chunk:
                        hash_obj.update(chunk)
                        chunk = f.read(4096)
                        
                file_hash = hash_obj.hexdigest()
                file_size = file_path.stat().st_size
                
                if file_hash in hash_map:
                    # Duplicate found
                    dupes_found += 1
                    dupes_size += file_size
                    
                    # Keep only the original
                    os.remove(file_path)
                    
                    # Create symlink to original
                    os.symlink(hash_map[file_hash], file_path)
                else:
                    hash_map[file_hash] = file_path
            
            total_saved += dupes_size
            
            self.logger.info(f"Found {dupes_found} duplicate files, saved {self._human_readable_size(dupes_size)}")
            self.logger.info(f"Total space saved: {self._human_readable_size(total_saved)}")
            
            return total_saved
            
        except Exception as e:
            self.logger.error(f"Failed to optimize backup size: {str(e)}")
            return 0

    async def merge_backups(self, base_backup_path: Path, incremental_path: Path) -> Path:
        """Merge an incremental backup with its base backup to create a full backup"""
        try:
            self.logger.info(f"Merging base backup {base_backup_path} with incremental {incremental_path}")
            
            # Check if both backups exist
            if not base_backup_path.exists() or not incremental_path.exists():
                raise FileNotFoundError("One or both backup paths do not exist")
                
            # Create new merged backup directory
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            device_model = self.device_info.model.replace(" ", "_")
            merged_dir = self.backup_root / f"{device_model}_merged_{timestamp}"
            
            os.makedirs(merged_dir, exist_ok=True)
            os.makedirs(merged_dir / "apps", exist_ok=True)
            os.makedirs(merged_dir / "data", exist_ok=True)
            os.makedirs(merged_dir / "system", exist_ok=True)
            
            # Copy all files from base backup
            self.logger.info("Copying files from base backup...")
            for src_path in base_backup_path.glob('**/*'):
                if not src_path.is_file():
                    continue
                    
                # Get relative path
                rel_path = src_path.relative_to(base_backup_path)
                dest_path = merged_dir / rel_path
                
                # Create directories if needed
                os.makedirs(dest_path.parent, exist_ok=True)
                
                # Copy file
                shutil.copy2(src_path, dest_path)
                
            # Overwrite with files from incremental backup
            self.logger.info("Applying incremental changes...")
            for src_path in incremental_path.glob('**/*'):
                if not src_path.is_file() or src_path.name in ["incremental_manifest.json", "base_backup.txt"]:
                    continue
                    
                # Get relative path
                rel_path = src_path.relative_to(incremental_path)
                dest_path = merged_dir / rel_path
                
                # Create directories if needed
                os.makedirs(dest_path.parent, exist_ok=True)
                
                # Copy file (overwrite)
                shutil.copy2(src_path, dest_path)
                
            # Create merged manifest
            base_manifest_path = base_backup_path / "manifest.json"
            incr_manifest_path = incremental_path / "incremental_manifest.json"
            
            async with aiofiles.open(base_manifest_path, 'r') as f:
                base_manifest = json.loads(await f.read())
                
            async with aiofiles.open(incr_manifest_path, 'r') as f:
                incr_manifest = json.loads(await f.read())
                
            # Update apps list
            base_apps = {app['package']: app for app in base_manifest.get('apps', [])}
            
            # Add/update apps from incremental backup
            for app in incr_manifest.get('apps', []):
                base_apps[app['package']] = app
                
            # Create new manifest
            merged_manifest = base_manifest.copy()
            merged_manifest['apps'] = list(base_apps.values())
            merged_manifest['timestamp'] = datetime.now().isoformat()
            merged_manifest['merged_from'] = {
                'base': base_backup_path.name,
                'incremental': incremental_path.name
            }
            
            # Save merged manifest
            async with aiofiles.open(merged_dir / "manifest.json", 'w') as f:
                await f.write(json.dumps(merged_manifest, indent=2))
                
            self.logger.info(f"Backups successfully merged into {merged_dir}")
            return merged_dir
            
        except Exception as e:
            self.logger.error(f"Failed to merge backups: {str(e)}")
            raise
            
    async def generate_report(self, backup_path: Path) -> str:
        """Generate a detailed report of backup contents"""
        try:
            report_data = {
                "backup_name": backup_path.name,
                "timestamp": datetime.now().isoformat(),
                "apps": {
                    "total": 0,
                    "system": 0,
                    "user": 0,
                    "details": []
                },
                "storage": {
                    "total_size": 0,
                    "app_data_size": 0,
                    "apk_size": 0
                },
                "system_files": []
            }
            
            # Load manifest
            manifest_path = backup_path / "manifest.json"
            if manifest_path.exists():
                async with aiofiles.open(manifest_path, 'r') as f:
                    manifest = json.loads(await f.read())
                    
                # Extract app details
                apps = manifest.get('apps', [])
                report_data["apps"]["total"] = len(apps)
                
                for app in apps:
                    is_system = app.get('system', False)
                    if is_system:
                        report_data["apps"]["system"] += 1
                    else:
                        report_data["apps"]["user"] += 1
                        
                    # Get app size
                    apk_path = backup_path / "apps" / f"{app['package']}.apk"
                    data_path = backup_path / "data" / app['package']
                    
                    apk_size = apk_path.stat().st_size if apk_path.exists() else 0
                    data_size = sum(f.stat().st_size for f in data_path.glob('**/*') if f.is_file()) if data_path.exists() else 0
                    
                    report_data["storage"]["apk_size"] += apk_size
                    report_data["storage"]["app_data_size"] += data_size
                    
                    # Add to app details
                    report_data["apps"]["details"].append({
                        "package": app['package'],
                        "name": app.get('label', app['package']),
                        "version": app.get('version_name', 'unknown'),
                        "is_system": is_system,
                        "apk_size": self._human_readable_size(apk_size),
                        "data_size": self._human_readable_size(data_size)
                    })
                    
            # Calculate total size
            report_data["storage"]["total_size"] = sum(f.stat().st_size for f in backup_path.glob('**/*') if f.is_file())
            
            # Add system files
            system_dir = backup_path / "system"
            if system_dir.exists():
                for file_path in system_dir.glob('**/*'):
                    if file_path.is_file():
                        rel_path = file_path.relative_to(system_dir)
                        size = file_path.stat().st_size
                        
                        report_data["system_files"].append({
                            "path": str(rel_path),
                            "size": self._human_readable_size(size)
                        })
            
            # Generate HTML report
            html_report = self._generate_html_report(report_data)
            
            # Save report
            report_path = backup_path / "backup_report.html"
            async with aiofiles.open(report_path, 'w') as f:
                await f.write(html_report)
                
            self.logger.info(f"Backup report generated: {report_path}")
            return str(report_path)
            
        except Exception as e:
            self.logger.error(f"Failed to generate backup report: {str(e)}")
            return ""
            
    def _generate_html_report(self, data: Dict) -> str:
        """Generate HTML report from report data"""
        # Format sizes for display
        total_size = self._human_readable_size(data["storage"]["total_size"])
        app_data_size = self._human_readable_size(data["storage"]["app_data_size"])
        apk_size = self._human_readable_size(data["storage"]["apk_size"])
        
        # Sort apps by size (largest first)
        sorted_apps = sorted(data["apps"]["details"], 
                             key=lambda x: self._parse_size_to_bytes(x["data_size"]) + self._parse_size_to_bytes(x["apk_size"]), 
                             reverse=True)
                             
        # Create HTML report
        html = f"""
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Backup Report - {data['backup_name']}</title>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 0; padding: 20px; color: #333; }}
                h1, h2, h3 {{ color: #444; }}
                .container {{ max-width: 1200px; margin: 0 auto; }}
                .summary-box {{ background: #f8f9fa; border-radius: 5px; padding: 15px; margin-bottom: 20px; }}
                .summary-box h3 {{ margin-top: 0; }}
                .grid {{ display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }}
                table {{ width: 100%; border-collapse: collapse; margin: 20px 0; }}
                th, td {{ padding: 12px 15px; text-align: left; border-bottom: 1px solid #ddd; }}
                th {{ background-color: #f8f9fa; }}
                tr:hover {{ background-color: #f1f1f1; }}
                .system-app {{ background-color: #fff8f8; }}
                .progress-bar-container {{ width: 100%; background-color: #e0e0e0; height: 20px; border-radius: 10px; overflow: hidden; }}
                .progress-bar {{ height: 100%; color: white; text-align: center; line-height: 20px; }}
                .user-apps {{ background-color: #4caf50; }}
                .system-apps {{ background-color: #2196F3; }}
            </style>
        </head>
        <body>
            <div class="container">
                <h1>Backup Report</h1>
                
                <div class="summary-box">
                    <h3>Backup Summary</h3>
                    <p><strong>Backup Name:</strong> {data['backup_name']}</p>
                    <p><strong>Generated:</strong> {data['timestamp']}</p>
                    <p><strong>Total Size:</strong> {total_size}</p>
                </div>
                
                <div class="grid">
                    <div class="summary-box">
                        <h3>App Statistics</h3>
                        <p><strong>Total Apps:</strong> {data['apps']['total']}</p>
                        <p><strong>User Apps:</strong> {data['apps']['user']}</p>
                        <p><strong>System Apps:</strong> {data['apps']['system']}</p>
                        
                        <div class="progress-bar-container">
                            <div class="progress-bar user-apps" style="width: {data['apps']['user']/max(data['apps']['total'], 1)*100}%">
                                User
                            </div>
                        </div>
                        <div class="progress-bar-container">
                            <div class="progress-bar system-apps" style="width: {data['apps']['system']/max(data['apps']['total'], 1)*100}%">
                                System
                            </div>
                        </div>
                    </div>
                    
                    <div class="summary-box">
                        <h3>Storage Breakdown</h3>
                        <p><strong>Total Size:</strong> {total_size}</p>
                        <p><strong>Application Data:</strong> {app_data_size} ({data['storage']['app_data_size']/max(data['storage']['total_size'], 1)*100:.1f}%)</p>
                        <p><strong>APK Files:</strong> {apk_size} ({data['storage']['apk_size']/max(data['storage']['total_size'], 1)*100:.1f}%)</p>
                    </div>
                </div>
                
                <h2>Application Details</h2>
                <table>
                    <tr>
                        <th>App Name</th>
                        <th>Package</th>
                        <th>Version</th>
                        <th>APK Size</th>
                        <th>Data Size</th>
                        <th>Type</th>
                    </tr>
        """
        
        # Add app rows
        for app in sorted_apps:
            app_class = "system-app" if app['is_system'] else ""
            html += f"""
                    <tr class="{app_class}">
                        <td>{app['name']}</td>
                        <td>{app['package']}</td>
                        <td>{app['version']}</td>
                        <td>{app['apk_size']}</td>
                        <td>{app['data_size']}</td>
                        <td>{'System' if app['is_system'] else 'User'}</td>
                    </tr>
            """
            
        # Add system files section if there are any
        if data['system_files']:
            html += f"""
                </table>
                
                <h2>System Files</h2>
                <table>
                    <tr>
                        <th>Path</th>
                        <th>Size</th>
                    </tr>
            """
            
            for file in data['system_files']:
                html += f"""
                    <tr>
                        <td>{file['path']}</td>
                        <td>{file['size']}</td>
                    </tr>
                """
                
        # Close HTML document
        html += """
                </table>
            </div>
        </body>
        </html>
        """
        
        return html
        
    def _parse_size_to_bytes(self, size_str: str) -> int:
        """Parse human-readable size back to bytes"""
        try:
            if "GB" in size_str:
                return int(float(size_str.replace(" GB", "")) * 1024 * 1024 * 1024)
            elif "MB" in size_str:
                return int(float(size_str.replace(" MB", "")) * 1024 * 1024)
            elif "KB" in size_str:
                return int(float(size_str.replace(" KB", "")) * 1024)
            else:
                return int(float(size_str.replace(" B", "")))
        except Exception:
            return 0        
            
    async def export_app_list(self, backup_path: Path, format: str = "csv") -> str:
        """Export list of apps in the backup to CSV or JSON format"""
        try:
            # Load manifest
            manifest_path = backup_path / "manifest.json"
            if not manifest_path.exists():
                self.logger.error("Backup manifest not found")
                return ""
                
            async with aiofiles.open(manifest_path, 'r') as f:
                manifest = json.loads(await f.read())
                
            apps = manifest.get('apps', [])
            if not apps:
                self.logger.warning("No apps found in backup")
                return ""
                
            # Prepare output path
            export_file = backup_path / f"app_list.{format.lower()}"
            
            if format.lower() == "csv":
                # Create CSV file
                async with aiofiles.open(export_file, 'w', newline='') as f:
                    await f.write("Package,App Name,Version,System App,Install Date\n")
                    
                    for app in apps:
                        pkg = app['package']
                        name = app.get('label', pkg)
                        version = app.get('version_name', 'unknown')
                        is_system = "Yes" if app.get('system', False) else "No"
                        install_date = app.get('first_install_time', 'unknown')
                        
                        await f.write(f'"{pkg}","{name}","{version}","{is_system}","{install_date}"\n')
            
            elif format.lower() == "json":
                # Create JSON file with simplified app info
                simplified_apps = []
                for app in apps:
                    simplified_apps.append({
                        'package': app['package'],
                        'name': app.get('label', app['package']),
                        'version': app.get('version_name', 'unknown'),
                        'system': app.get('system', False),
                        'install_date': app.get('first_install_time', 'unknown')
                    })
                    
                async with aiofiles.open(export_file, 'w') as f:
                    await f.write(json.dumps({'apps': simplified_apps}, indent=2))
            else:
                self.logger.error(f"Unsupported export format: {format}")
                return ""
                
            self.logger.info(f"App list exported to {export_file}")
            return str(export_file)
            
        except Exception as e:
            self.logger.error(f"Failed to export app list: {str(e)}")
            return ""
    
    async def extract_app_from_backup(self, backup_path: Path, package: str, dest_dir: Path) -> bool:
        """Extract a single app and its data from a backup"""
        try:
            # Check if backup exists
            if not backup_path.exists():
                self.logger.error(f"Backup not found: {backup_path}")
                return False
                
            # Create destination directory
            os.makedirs(dest_dir, exist_ok=True)
            
            # Extract APK
            apk_path = backup_path / "apps" / f"{package}.apk"
            if apk_path.exists():
                dest_apk = dest_dir / f"{package}.apk"
                shutil.copy2(apk_path, dest_apk)
                self.logger.info(f"APK extracted to {dest_apk}")
            else:
                self.logger.warning(f"APK for {package} not found in backup")
                
            # Extract app data
            data_path = backup_path / "data" / package
            if data_path.exists() and data_path.is_dir():
                dest_data = dest_dir / "data"
                os.makedirs(dest_data, exist_ok=True)
                
                # Copy data directory
                shutil.copytree(data_path, dest_data / package, dirs_exist_ok=True)
                self.logger.info(f"App data extracted to {dest_data / package}")
            else:
                self.logger.warning(f"App data for {package} not found in backup")
                
            # Extract permissions
            perm_file = backup_path / f"{package}.permissions"
            if perm_file.exists():
                dest_perm = dest_dir / f"{package}.permissions"
                shutil.copy2(perm_file, dest_perm)
                self.logger.info(f"Permissions extracted to {dest_perm}")
                
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to extract app from backup: {str(e)}")
            return False
    
    def get_backup_status(self) -> Dict:
        """Get current backup status and progress"""
        if not self._progress:
            return {
                "status": "idle",
                "progress": 0,
                "message": "No backup in progress"
            }
            
        return {
            "status": self._progress.get('status', 'unknown'),
            "progress": self._progress.get('progress', 0),
            "current": self._progress.get('current', 0),
            "total": self._progress.get('total', 0),
            "message": self._progress.get('message', ''),
            "errors": self._progress.get('errors', [])
        }
        
    async def cancel_backup(self) -> bool:
        """Cancel ongoing backup process"""
        if self._task and not self._task.done():
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                self.logger.info("Backup process canceled")
                self._progress = {
                    "status": "canceled",
                    "progress": 0,
                    "message": "Backup was canceled"
                }
                return True
            except Exception as e:
                self.logger.error(f"Error canceling backup: {str(e)}")
                
        return False
        
    def __del__(self):
        """Cleanup when object is destroyed"""
        # Close any open resources
        if hasattr(self, 'device') and self.device:
            try:
                asyncio.create_task(self.device.close())
            except Exception:
                pass           
                
async def _cleanup_old_backups(self, config: BackupConfig, max_backups: int):
        """Remove old backups to maintain maximum count"""
        if max_backups <= 0:
            return
            
        try:
            # Find all backups
            backups = await self.list_backups()
            
            # Filter backups by device if specified
            if config.device_id:
                device_backups = [b for b in backups if config.device_id in b.get('path', '')]
            else:
                device_backups = backups
                
            # If number of backups exceeds max, remove oldest
            if len(device_backups) > max_backups:
                # Sort by timestamp (oldest first)
                device_backups.sort(key=lambda x: x.get('timestamp', ''))
                
                # Remove oldest backups
                for i in range(len(device_backups) - max_backups):
                    backup_path = device_backups[i]['path']
                    await self.delete_backup(backup_path)
                    self.logger.info(f"Removed old backup to maintain maximum count: {backup_path}")
        except Exception as e:
            self.logger.warning(f"Failed to clean up old backups: {str(e)}")

    async def validate_device_connection(self) -> bool:
        """Validate that the device is properly connected and accessible"""
        try:
            # Check if device is connected
            if not self.device:
                self.logger.error("No device connected")
                return False
                
            # Try to execute a simple command
            result = await self.device.shell("echo connection_test")
            
            if "connection_test" in result:
                # Get device information
                self.logger.info(f"Connected to device: {self.device_info.model} ({self.device_info.device_id})")
                return True
            else:
                self.logger.error("Failed to communicate with device")
                return False
                
        except Exception as e:
            self.logger.error(f"Device connection validation failed: {str(e)}")
            return False
            
    async def check_backup_compatibility(self, backup_path: Path) -> Dict:
        """Check if a backup is compatible with the currently connected device"""
        result = {
            "compatible": False,
            "warnings": [],
            "critical_issues": []
        }
        
        try:
            # Check if backup exists
            if not backup_path.exists():
                result["critical_issues"].append("Backup path does not exist")
                return result
                
            # Load backup metadata
            metadata_path = backup_path / "metadata.json"
            if not metadata_path.exists():
                result["critical_issues"].append("Backup metadata not found")
                return result
                
            async with aiofiles.open(metadata_path, 'r') as f:
                metadata = json.loads(await f.read())
                
            # Check device compatibility
            backup_device = metadata.get('device', {})
            
            # Check Android version
            backup_android = backup_device.get('android_version')
            current_android = self.device_info.android_version
            
            if backup_android and current_android:
                # Major version difference is a warning
                if backup_android.split('.')[0] != current_android.split('.')[0]:
                    result["warnings"].append(f"Android version mismatch: backup from {backup_android}, current device is {current_android}")
            
            # Check device model
            backup_model = backup_device.get('model')
            current_model = self.device_info.model
            
            if backup_model != current_model:
                result["warnings"].append(f"Device model mismatch: backup from {backup_model}, current device is {current_model}")
                
            # Check for root access if backup contains app data
            if metadata.get('has_app_data', False) and not self.device_info.is_rooted:
                result["critical_issues"].append("Backup contains app data but current device is not rooted")
                
            # Calculate compatibility score
            if len(result["critical_issues"]) == 0:
                result["compatible"] = True
                if len(result["warnings"]) > 0:
                    result["compatibility_level"] = "partial"
                else:
                    result["compatibility_level"] = "full"
                    
            return result
            
        except Exception as e:
            self.logger.error(f"Failed to check backup compatibility: {str(e)}")
            result["critical_issues"].append(f"Error checking compatibility: {str(e)}")
            return result
            
    async def notify_backup_complete(self, backup_path: Path, success: bool = True):
        """Send notification about backup completion"""
        if not self.notification_manager:
            return
            
        try:
            if success:
                title = "Backup Completed Successfully"
                
                # Get backup stats
                manifest_path = backup_path / "manifest.json"
                if manifest_path.exists():
                    async with aiofiles.open(manifest_path, 'r') as f:
                        manifest = json.loads(await f.read())
                        
                    app_count = len(manifest.get('apps', []))
                    
                    # Calculate total size
                    total_size = sum(f.stat().st_size for f in backup_path.glob('**/*') if f.is_file())
                    size_str = self._human_readable_size(total_size)
                    
                    message = f"Backed up {app_count} apps ({size_str}) to {backup_path.name}"
                else:
                    message = f"Backup saved to {backup_path.name}"
            else:
                title = "Backup Failed"
                message = "There was an error during the backup process. Check logs for details."
                
            # Send notification
            await self.notification_manager.send_notification(title, message, {"backup_path": str(backup_path)})
            
        except Exception as e:
            self.logger.error(f"Failed to send notification: {str(e)}")

    @property
    def is_busy(self) -> bool:
        """Check if a backup or restore operation is in progress"""
        return self._task is not None and not self._task.done()
        
    def get_version(self) -> str:
        """Return the version of the backup utility"""
        return "1.0.0"
        
    async def backup_external_storage(self, backup_dir: Path, include_paths: List[str] = None):
        """Backup selected files and directories from external storage"""
        try:
            ext_storage_dir = backup_dir / "external_storage"
            os.makedirs(ext_storage_dir, exist_ok=True)
            
            # Default paths to include if none specified
            if not include_paths:
                include_paths = [
                    "DCIM",
                    "Pictures",
                    "Download",
                    "Documents"
                ]
                
            self.logger.info(f"Starting backup of external storage: {include_paths}")
            
            # Check if external storage is accessible
            storage_check = await self.device.shell("ls -la /sdcard/")
            if "Permission denied" in storage_check or not storage_check.strip():
                self.logger.error("Cannot access external storage. Check permissions.")
                return False
                
            total_files = 0
            total_size = 0
            
            # Process each included path
            for path in include_paths:
                # Sanitize path to prevent command injection
                safe_path = path.replace('"', '').replace("'", "").replace(";", "").replace("&", "")
                
                # Get list of files
                find_cmd = f"find /sdcard/{safe_path} -type f 2>/dev/null"
                file_list = await self.device.shell(find_cmd)
                
                files = [f for f in file_list.splitlines() if f.strip()]
                if not files:
                    self.logger.info(f"No files found in /sdcard/{safe_path}")
                    continue
                    
                # Create directory structure
                for file_path in files:
                    try:
                        # Extract relative path
                        rel_path = file_path.replace("/sdcard/", "")
                        dest_path = ext_storage_dir / rel_path
                        
                        # Create directory structure
                        os.makedirs(dest_path.parent, exist_ok=True)
                        
                        # Pull file
                        await self.device.pull(file_path, dest_path)
                        
                        # Update counters
                        total_files += 1
                        total_size += dest_path.stat().st_size
                        
                        if total_files % 50 == 0:
                            self.logger.info(f"Backed up {total_files} files ({self._human_readable_size(total_size)})")
                            
                    except Exception as e:
                        self.logger.warning(f"Failed to backup {file_path}: {str(e)}")
                        
            self.logger.info(f"External storage backup completed: {total_files} files ({self._human_readable_size(total_size)})")
            return True
            
        except Exception as e:
            self.logger.error(f"External storage backup failed: {str(e)}")
            return False
            
    async def restore_external_storage(self, backup_dir: Path):
        """Restore backed up external storage files"""
        try:
            ext_storage_dir = backup_dir / "external_storage"
            if not ext_storage_dir.exists():
                self.logger.warning("No external storage backup found")
                return False
                
            self.logger.info("Starting restoration of external storage files")
            
            # Check if external storage is writable
            write_test = await self.device.shell("touch /sdcard/write_test && rm /sdcard/write_test")
            if "Permission denied" in write_test:
                self.logger.error("Cannot write to external storage. Check permissions.")
                return False
                
            # Get all files in backup
            files = list(ext_storage_dir.glob('**/*'))
            files = [f for f in files if f.is_file()]
            
            total_files = len(files)
            restored_files = 0
            
            for i, file_path in enumerate(files):
                try:
                    # Get relative path
                    rel_path = file_path.relative_to(ext_storage_dir)
                    device_path = f"/sdcard/{rel_path}"
                    
                    # Create directory on device if needed
                    dir_path = os.path.dirname(device_path)
                    await self.device.shell(f"mkdir -p '{dir_path}'")
                    
                    # Push file
                    await self.device.push(str(file_path), device_path)
                    restored_files += 1
                    
                    if (i + 1) % 50 == 0:
                        self.logger.info(f"Restored {i+1}/{total_files} files")
                        
                except Exception as e:
                    self.logger.warning(f"Failed to restore {rel_path}: {str(e)}")
            
            self.logger.info(f"External storage restoration completed: {restored_files}/{total_files} files restored")
            return restored_files > 0
            
        except Exception as e:
            self.logger.error(f"External storage restoration failed: {str(e)}")
            return False
    
    async def compression_stats(self, backup_dir: Path) -> Dict:
        """Calculate compression statistics for a backup"""
        stats = {
            "original_size": 0,
            "compressed_size": 0,
            "compression_ratio": 0,
            "space_saved": 0,
            "format": self.config.compression_format
        }
        
        try:
            # Check if we're using compression
            if not self.config.compress_backup:
                return stats
                
            # Get all compressed files
            if self.config.compression_format == "zip":
                compressed_files = list(backup_dir.glob('**/*.zip'))
            elif self.config.compression_format == "tar.gz":
                compressed_files = list(backup_dir.glob('**/*.tar.gz'))
            else:
                return stats
                
            # Calculate stats
            for file_path in compressed_files:
                stats["compressed_size"] += file_path.stat().st_size
                
                # Extract original size from archives
                if self.config.compression_format == "zip":
                    with zipfile.ZipFile(file_path, 'r') as zip_file:
                        for info in zip_file.infolist():
                            stats["original_size"] += info.file_size
                elif self.config.compression_format == "tar.gz":
                    with tarfile.open(file_path, 'r:gz') as tar_file:
                        for info in tar_file.getmembers():
                            stats["original_size"] += info.size
            
            # Calculate ratio and space saved
            if stats["original_size"] > 0:
                stats["compression_ratio"] = stats["original_size"] / stats["compressed_size"]
                stats["space_saved"] = stats["original_size"] - stats["compressed_size"]
                stats["space_saved_percent"] = (stats["space_saved"] / stats["original_size"]) * 100
                
            return stats
            
        except Exception as e:
            self.logger.error(f"Failed to calculate compression statistics: {str(e)}")
            return stats
    
    async def create_bootloader_backup(self, backup_dir: Path) -> bool:
        """Create backup of bootloader partitions (requires root)"""
        if not self.device_info.is_rooted:
            self.logger.error("Root access required for bootloader backup")
            return False
            
        try:
            # Create bootloader directory
            bootloader_dir = backup_dir / "bootloader"
            os.makedirs(bootloader_dir, exist_ok=True)
            
            # Common partitions to backup
            partitions = [
                "boot", "recovery", "system", "vendor", "dtbo", "vbmeta"
            ]
            
            # Find block devices
            block_list = await self._execute_adb_command("ls -la /dev/block/by-name/", as_root=True)
            
            backed_up = []
            
            for partition in partitions:
                try:
                    # Find device path
                    match = re.search(f"{partition} -> ([^\n]+)", block_list)
                    if not match:
                        self.logger.warning(f"Partition {partition} not found")
                        continue
                        
                    device_path = match.group(1)
                    if not device_path.startswith("/"):
                        device_path = f"/dev/block/by-name/{device_path}"
                        
                    # Create backup using DD
                    output_file = f"/data/local/tmp/{partition}.img"
                    dd_cmd = f"dd if={device_path} of={output_file} bs=4096"
                    await self._execute_adb_command(dd_cmd, as_root=True)
                    
                    # Pull the image
                    dest_path = bootloader_dir / f"{partition}.img"
                    await self.device.pull(output_file, dest_path)
                    
                    # Clean up
                    await self._execute_adb_command(f"rm {output_file}", as_root=True)
                    
                    backed_up.append(partition)
                    self.logger.info(f"Backed up {partition} partition")
                    
                except Exception as e:
                    self.logger.warning(f"Failed to backup {partition} partition: {str(e)}")
            
            self.logger.info(f"Bootloader backup completed for partitions: {', '.join(backed_up)}")
            return len(backed_up) > 0
            
        except Exception as e:
            self.logger.error(f"Bootloader backup failed: {str(e)}")
            return False
            
    def finalize(self):
        """Finalize and clean up"""
        # Close resources
        if hasattr(self, 'device') and self.device:
            try:
                asyncio.get_event_loop().run_until_complete(self.device.close())
            except Exception:
                pass         
                
    async def create_backup_archive(self, backup_dir: Path, archive_format: str = "zip") -> Path:
        """Create a single archive file of the entire backup"""
        try:
            # Determine archive path
            archive_path = Path(f"{backup_dir}.{archive_format}")
            
            self.logger.info(f"Creating backup archive: {archive_path}")
            
            if archive_format == "zip":
                # Create zip archive
                with zipfile.ZipFile(archive_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
                    for root, _, files in os.walk(backup_dir):
                        for file in files:
                            file_path = Path(root) / file
                            rel_path = file_path.relative_to(backup_dir)
                            zipf.write(file_path, rel_path)
                            
            elif archive_format == "tar.gz":
                # Create tar.gz archive
                with tarfile.open(archive_path, "w:gz") as tar:
                    tar.add(backup_dir, arcname=os.path.basename(backup_dir))
                    
            elif archive_format == "tar.bz2":
                # Create tar.bz2 archive
                with tarfile.open(archive_path, "w:bz2") as tar:
                    tar.add(backup_dir, arcname=os.path.basename(backup_dir))
            else:
                self.logger.error(f"Unsupported archive format: {archive_format}")
                return None
                
            self.logger.info(f"Backup archive created: {archive_path} ({self._human_readable_size(archive_path.stat().st_size)})")
            return archive_path
            
        except Exception as e:
            self.logger.error(f"Failed to create backup archive: {str(e)}")
            return None
            
    async def extract_backup_archive(self, archive_path: Path, extract_dir: Path = None) -> Path:
        """Extract a backup archive"""
        try:
            # Determine extraction directory
            if extract_dir is None:
                extract_dir = archive_path.parent / archive_path.stem
                
            self.logger.info(f"Extracting backup archive to {extract_dir}")
            
            # Create extraction directory
            os.makedirs(extract_dir, exist_ok=True)
            
            # Extract based on format
            if archive_path.suffix == ".zip":
                with zipfile.ZipFile(archive_path, 'r') as zipf:
                    zipf.extractall(extract_dir)
                    
            elif archive_path.name.endswith(".tar.gz"):
                with tarfile.open(archive_path, "r:gz") as tar:
                    tar.extractall(extract_dir)
                    
            elif archive_path.name.endswith(".tar.bz2"):
                with tarfile.open(archive_path, "r:bz2") as tar:
                    tar.extractall(extract_dir)
            else:
                self.logger.error(f"Unsupported archive format: {archive_path.suffix}")
                return None
                
            self.logger.info(f"Backup archive extracted to {extract_dir}")
            return extract_dir
            
        except Exception as e:
            self.logger.error(f"Failed to extract backup archive: {str(e)}")
            return None
            
    async def backup_sms_messages(self, backup_dir: Path) -> bool:
        """Backup SMS messages (requires root)"""
        if not self.device_info.is_rooted:
            self.logger.warning("Root access required for SMS backup")
            return False
            
        try:
            # Create SMS directory
            sms_dir = backup_dir / "sms"
            os.makedirs(sms_dir, exist_ok=True)
            
            # Define paths for different Android versions
            mmssms_paths = [
                "/data/data/com.android.providers.telephony/databases/mmssms.db",
                "/data/user_de/0/com.android.providers.telephony/databases/mmssms.db"
            ]
            
            backed_up = False
            
            for db_path in mmssms_paths:
                try:
                    # Check if file exists
                    check_cmd = f"[ -f {db_path} ] && echo exists"
                    result = await self._execute_adb_command(check_cmd, as_root=True)
                    
                    if "exists" not in result:
                        continue
                        
                    # Copy to temp location
                    temp_path = "/data/local/tmp/mmssms.db"
                    copy_cmd = f"cp {db_path} {temp_path} && chmod 644 {temp_path}"
                    await self._execute_adb_command(copy_cmd, as_root=True)
                    
                    # Pull the database
                    local_path = sms_dir / "mmssms.db"
                    await self.device.pull(temp_path, local_path)
                    
                    # Clean up
                    await self._execute_adb_command(f"rm {temp_path}", as_root=True)
                    
                    backed_up = True
                    self.logger.info(f"SMS database backed up from {db_path}")
                    break
                    
                except Exception as e:
                    self.logger.warning(f"Failed to backup SMS from {db_path}: {str(e)}")
            
            if not backed_up:
                self.logger.warning("Could not backup SMS messages")
                return False
                
            # Create a JSON export of messages for easier viewing
            try:
                # Connect to the database
                conn = sqlite3.connect(str(sms_dir / "mmssms.db"))
                conn.row_factory = sqlite3.Row
                cursor = conn.cursor()
                
                # Query SMS messages
                cursor.execute("""
                SELECT 
                    _id, address, date, body, type, read
                FROM sms
                ORDER BY date DESC
                """)
                
                messages = []
                for row in cursor.fetchall():
                    messages.append({
                        'id': row['_id'],
                        'address': row['address'],
                        'date': row['date'],
                        'date_formatted': datetime.fromtimestamp(row['date']/1000).isoformat(),
                        'body': row['body'],
                        'type': 'incoming' if row['type'] == 1 else 'outgoing',
                        'read': bool(row['read'])
                    })
                
                # Save as JSON
                async with aiofiles.open(sms_dir / "messages.json", 'w') as f:
                    await f.write(json.dumps(messages, indent=2))
                    
                self.logger.info(f"Exported {len(messages)} SMS messages")
                
            except Exception as e:
                self.logger.warning(f"Failed to create JSON export of SMS: {str(e)}")
            
            return backed_up
            
        except Exception as e:
            self.logger.error(f"SMS backup failed: {str(e)}")
            return False

    async def backup_call_logs(self, backup_dir: Path) -> bool:
        """Backup call logs (requires permissions)"""
        try:
            # Create calls directory
            calls_dir = backup_dir / "calls"
            os.makedirs(calls_dir, exist_ok=True)
            
            # Use content query to get call logs
            cmd = "content query --uri content://call_log/calls"
            result = await self.device.shell(cmd)
            
            if "Permission Denial" in result:
                self.logger.warning("Permission denied when accessing call logs")
                return False
                
            # Parse the output
            calls = []
            current_call = {}
            
            for line in result.splitlines():
                if line.startswith("Row:"):
                    if current_call:
                        calls.append(current_call)
                    current_call = {}
                elif "=" in line:
                    key, value = line.split("=", 1)
                    key = key.strip()
                    value = value.strip()
                    current_call[key] = value
                    
            if current_call:
                calls.append(current_call)
                
            if not calls:
                self.logger.warning("No call logs found or unable to access them")
                return False
                
            # Save as JSON
            async with aiofiles.open(calls_dir / "call_logs.json", 'w') as f:
                await f.write(json.dumps(calls, indent=2))
                
            self.logger.info(f"Backed up {len(calls)} call log entries")
            return True
            
        except Exception as e:
            self.logger.error(f"Call log backup failed: {str(e)}")
            return False
            
    async def restore_sms_messages(self, backup_dir: Path) -> bool:
        """Restore SMS messages (requires root)"""
        if not self.device_info.is_rooted:
            self.logger.warning("Root access required for SMS restoration")
            return False
            
        try:
            # Check if SMS backup exists
            sms_db_path = backup_dir / "sms" / "mmssms.db"
            if not sms_db_path.exists():
                self.logger.warning("SMS backup database not found")
                return False
                
            # Define paths for different Android versions
            mmssms_paths = [
                "/data/data/com.android.providers.telephony/databases/mmssms.db",
                "/data/user_de/0/com.android.providers.telephony/databases/mmssms.db"
            ]
            
            # Find the correct path on device
            target_path = None
            for db_path in mmssms_paths:
                check_cmd = f"[ -f {db_path} ] && echo exists"
                result = await self._execute_adb_command(check_cmd, as_root=True)
                
                if "exists" in result:
                    target_path = db_path
                    break
                    
            if not target_path:
                self.logger.error("Could not find SMS database location on device")
                return False
                
            # Copy to temporary location
            temp_path = "/data/local/tmp/mmssms_restore.db"
            await self.device.push(str(sms_db_path), temp_path)
            
            # Backup current database
            backup_cmd = f"cp {target_path} {target_path}.bak"
            await self._execute_adb_command(backup_cmd, as_root=True)
            
            # Restore database
            restore_cmd = f"cp {temp_path} {target_path} && chmod 660 {target_path} && chown com.android.providers.telephony:com.android.providers.telephony {target_path}"
            await self._execute_adb_command(restore_cmd, as_root=True)
            
            # Clean up
            await self._execute_adb_command(f"rm {temp_path}", as_root=True)
            
            # Restart telephony provider
            restart_cmd = "am force-stop com.android.providers.telephony"
            await self._execute_adb_command(restart_cmd, as_root=True)
            
            self.logger.info("SMS messages restored successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"SMS restoration failed: {str(e)}")
            return False
            
    async def backup_contacts(self, backup_dir: Path) -> bool:
        """Backup contacts to vCard format"""
        try:
            # Create contacts directory
            contacts_dir = backup_dir / "contacts"
            os.makedirs(contacts_dir, exist_ok=True)
            
            # Use content query to get contacts
            cmd = "content query --uri content://contacts/data --projection display_name:data1:mimetype"
            result = await self.device.shell(cmd)
            
            if "Permission Denial" in result:
                self.logger.warning("Permission denied when accessing contacts")
                return False
                
            # Parse the output and organize by contact
            contacts = {}
            current_row = {}
            
            for line in result.splitlines():
                if line.startswith("Row:"):
                    if current_row and 'display_name' in current_row:
                        name = current_row['display_name']
                        if name not in contacts:
                            contacts[name] = {'name': name, 'numbers': [], 'emails': []}
                            
                        if current_row.get('mimetype') == 'vnd.android.cursor.item/phone_v2':
                            contacts[name]['numbers'].append(current_row.get('data1', ''))
                        elif current_row.get('mimetype') == 'vnd.android.cursor.item/email_v2':
                            contacts[name]['emails'].append(current_row.get('data1', ''))
                            
                    current_row = {}
                elif "=" in line:
                    key, value = line.split("=", 1)
                    key = key.strip()
                    value = value.strip()
                    current_row[key] = value
                    
            # Process the last row
            if current_row and 'display_name' in current_row:
                name = current_row['display_name']
                if name not in contacts:
                    contacts[name] = {'name': name, 'numbers': [], 'emails': []}
                    
                if current_row.get('mimetype') == 'vnd.android.cursor.item/phone_v2':
                    contacts[name]['numbers'].append(current_row.get('data1', ''))
                elif current_row.get('mimetype') == 'vnd.android.cursor.item/email_v2':
                    contacts[name]['emails'].append(current_row.get('data1', ''))
            
            # Create vCard file
            vcard_content = []
            for contact in contacts.values():
                vcard_content.append("BEGIN:VCARD")
                vcard_content.append("VERSION:3.0")
                vcard_content.append(f"FN:{contact['name']}")
                
                for number in contact['numbers']:
                    vcard_content.append(f"TEL:{number}")
                    
                for email in contact['emails']:
                    vcard_content.append(f"EMAIL:{email}")
                    
                vcard_content.append("END:VCARD")
                
            # Save vCard file
            async with aiofiles.open(contacts_dir / "contacts.vcf", 'w') as f:
                await f.write("\n".join(vcard_content))
                
            # Save as JSON for easier processing
            async with aiofiles.open(contacts_dir / "contacts.json", 'w') as f:
                await f.write(json.dumps(list(contacts.values()), indent=2))
                
            self.logger.info(f"Backed up {len(contacts)} contacts")
            return True
            
        except Exception as e:
            self.logger.error(f"Contacts backup failed: {str(e)}")
            return False
            
    async def restore_contacts(self, backup_dir: Path) -> bool:
        """Restore contacts from vCard format"""
        try:
            # Check if contacts backup exists
            vcard_path = backup_dir / "contacts" / "contacts.vcf"
            if not vcard_path.exists():
                self.logger.warning("Contacts backup not found")
                return False
                
            # Copy vCard to device
            device_vcard = "/sdcard/contacts_restore.vcf"
            await self.device.push(str(vcard_path), device_vcard)
            
            # Import contacts using intent
            import_cmd = f"am start -t text/vcard -d file://{device_vcard} -a android.intent.action.VIEW com.android.contacts"
            await self.device.shell(import_cmd)
            
            self.logger.info("Contacts restoration initiated. Please complete import on device.")
            return True
            
        except Exception as e:
            self.logger.error(f"Contacts restoration failed: {str(e)}")
            return False
 
    async def backup_wifi_settings(self, backup_dir: Path) -> bool:
        """Backup WiFi networks and settings (requires root)"""
        if not self.device_info.is_rooted:
            self.logger.warning("Root access required for WiFi settings backup")
            return False
            
        try:
            # Create WiFi directory
            wifi_dir = backup_dir / "wifi"
            os.makedirs(wifi_dir, exist_ok=True)
            
            # Define paths for WiFi configuration
            wifi_paths = [
                "/data/misc/wifi/WifiConfigStore.xml",
                "/data/misc/wifi/wpa_supplicant.conf",
                "/data/misc/wifi/networkHistory.txt",
                "/data/misc/wifi/softap.conf"
            ]
            
            backed_up = 0
            
            # Check if WPA supplicant is available via dumpsys
            try:
                dumpsys_cmd = "dumpsys wifi"
                wifi_data = await self._execute_adb_command(dumpsys_cmd, as_root=True)
                
                if wifi_data:
                    # Save dumpsys output
                    async with aiofiles.open(wifi_dir / "wifi_dumpsys.txt", 'w') as f:
                        await f.write(wifi_data)
                    backed_up += 1
                    
                    # Extract network information
                    networks = []
                    current_network = {}
                    in_network_section = False
                    
                    for line in wifi_data.splitlines():
                        if "Network Id" in line and "SSID" in line:
                            in_network_section = True
                            continue
                            
                        if in_network_section:
                            if line.strip() == "":
                                in_network_section = False
                                continue
                                
                            if line.strip().startswith("ID:"):
                                if current_network:
                                    networks.append(current_network)
                                current_network = {}
                                
                            parts = line.strip().split(': ', 1)
                            if len(parts) == 2:
                                key, value = parts
                                current_network[key.strip()] = value.strip()
                    
                    if current_network:
                        networks.append(current_network)
                        
                    # Save extracted networks
                    if networks:
                        async with aiofiles.open(wifi_dir / "wifi_networks.json", 'w') as f:
                            await f.write(json.dumps(networks, indent=2))
                        self.logger.info(f"Extracted {len(networks)} WiFi networks from dumpsys")
                        
            except Exception as e:
                self.logger.warning(f"Failed to extract WiFi info from dumpsys: {str(e)}")
            
            # Backup configuration files
            for path in wifi_paths:
                try:
                    # Check if file exists
                    check_cmd = f"[ -f {path} ] && echo exists"
                    result = await self._execute_adb_command(check_cmd, as_root=True)
                    
                    if "exists" not in result:
                        continue
                        
                    # Copy to temp location
                    file_name = os.path.basename(path)
                    temp_path = f"/data/local/tmp/{file_name}"
                    copy_cmd = f"cp {path} {temp_path} && chmod 644 {temp_path}"
                    await self._execute_adb_command(copy_cmd, as_root=True)
                    
                    # Pull the file
                    local_path = wifi_dir / file_name
                    await self.device.pull(temp_path, local_path)
                    
                    # Clean up
                    await self._execute_adb_command(f"rm {temp_path}", as_root=True)
                    
                    backed_up += 1
                    self.logger.info(f"Backed up WiFi configuration: {file_name}")
                    
                except Exception as e:
                    self.logger.warning(f"Failed to backup {path}: {str(e)}")
            
            if backed_up == 0:
                self.logger.warning("Could not backup any WiFi settings")
                return False
                
            self.logger.info(f"WiFi settings backup completed ({backed_up} files)")
            return True
            
        except Exception as e:
            self.logger.error(f"WiFi settings backup failed: {str(e)}")
            return False
            
    async def restore_wifi_settings(self, backup_dir: Path) -> bool:
        """Restore WiFi networks and settings (requires root)"""
        if not self.device_info.is_rooted:
            self.logger.warning("Root access required for WiFi settings restoration")
            return False
            
        try:
            # Check if WiFi backup exists
            wifi_dir = backup_dir / "wifi"
            if not wifi_dir.exists():
                self.logger.warning("WiFi settings backup not found")
                return False
                
            # Define target paths for WiFi configuration
            wifi_files = {
                "WifiConfigStore.xml": "/data/misc/wifi/WifiConfigStore.xml",
                "wpa_supplicant.conf": "/data/misc/wifi/wpa_supplicant.conf",
                "networkHistory.txt": "/data/misc/wifi/networkHistory.txt",
                "softap.conf": "/data/misc/wifi/softap.conf"
            }
            
            restored = 0
            
            # Restore configuration files
            for file_name, target_path in wifi_files.items():
                backup_file = wifi_dir / file_name
                if not backup_file.exists():
                    continue
                    
                try:
                    # Copy to temporary location
                    temp_path = f"/data/local/tmp/{file_name}"
                    await self.device.push(str(backup_file), temp_path)
                    
                    # Backup current file if exists
                    check_cmd = f"[ -f {target_path} ] && cp {target_path} {target_path}.bak"
                    await self._execute_adb_command(check_cmd, as_root=True)
                    
                    # Restore file
                    restore_cmd = f"cp {temp_path} {target_path} && chmod 600 {target_path} && chown wifi:wifi {target_path}"
                    await self._execute_adb_command(restore_cmd, as_root=True)
                    
                    # Clean up
                    await self._execute_adb_command(f"rm {temp_path}", as_root=True)
                    
                    restored += 1
                    self.logger.info(f"Restored WiFi configuration: {file_name}")
                    
                except Exception as e:
                    self.logger.warning(f"Failed to restore {file_name}: {str(e)}")
            
            if restored == 0:
                self.logger.warning("Could not restore any WiFi settings")
                return False
                
            # Restart WiFi service
            try:
                await self._execute_adb_command("svc wifi disable", as_root=True)
                await asyncio.sleep(2)
                await self._execute_adb_command("svc wifi enable", as_root=True)
                self.logger.info("WiFi service restarted")
            except Exception as e:
                self.logger.warning(f"Failed to restart WiFi service: {str(e)}")
                
            self.logger.info(f"WiFi settings restoration completed ({restored} files)")
            return True
            
        except Exception as e:
            self.logger.error(f"WiFi settings restoration failed: {str(e)}")
            return False
                      
    async def backup_battery_stats(self, backup_dir: Path) -> bool:
        """Backup battery usage statistics"""
        try:
            # Create battery directory
            battery_dir = backup_dir / "battery"
            os.makedirs(battery_dir, exist_ok=True)
            
            # Get battery stats from dumpsys
            battery_cmd = "dumpsys batterystats"
            battery_data = await self.device.shell(battery_cmd)
            
            if not battery_data:
                self.logger.warning("Could not retrieve battery statistics")
                return False
                
            # Save battery stats
            async with aiofiles.open(battery_dir / "batterystats.txt", 'w') as f:
                await f.write(battery_data)
                
            # Get battery health
            health_cmd = "dumpsys battery"
            health_data = await self.device.shell(health_cmd)
            
            if health_data:
                async with aiofiles.open(battery_dir / "battery_health.txt", 'w') as f:
                    await f.write(health_data)
                    
                # Extract key battery metrics
                metrics = {}
                for line in health_data.splitlines():
                    if ":" in line:
                        key, value = line.split(":", 1)
                        metrics[key.strip()] = value.strip()
                        
                async with aiofiles.open(battery_dir / "battery_metrics.json", 'w') as f:
                    await f.write(json.dumps(metrics, indent=2))
                    
            self.logger.info("Battery statistics backed up successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Battery statistics backup failed: {str(e)}")
            return False
            
    async def generate_backup_metadata(self, backup_dir: Path) -> Dict:
        """Generate and save metadata about the backup"""
        try:
            metadata = {
                "timestamp": datetime.now().isoformat(),
                "device": self.device_info.__dict__,
                "backup_version": self.get_version(),
                "stats": {
                    "total_size": 0,
                    "files_count": 0,
                    "apps_count": 0,
                    "system_apps_count": 0,
                    "user_apps_count": 0
                },
                "content": []
            }
            
            # Calculate stats
            total_size = 0
            files_count = 0
            
            for path in backup_dir.glob('**/*'):
                if path.is_file():
                    total_size += path.stat().st_size
                    files_count += 1
                    
            metadata["stats"]["total_size"] = total_size
            metadata["stats"]["files_count"] = files_count
            metadata["stats"]["total_size_human"] = self._human_readable_size(total_size)
            
            # Count apps
            manifest_path = backup_dir / "manifest.json"
            if manifest_path.exists():
                async with aiofiles.open(manifest_path, 'r') as f:
                    manifest = json.loads(await f.read())
                    
                apps = manifest.get('apps', [])
                metadata["stats"]["apps_count"] = len(apps)
                metadata["stats"]["system_apps_count"] = len([a for a in apps if a.get('system', False)])
                metadata["stats"]["user_apps_count"] = len([a for a in apps if not a.get('system', False)])
                
            # Document backup contents
            for item in backup_dir.glob('*'):
                if item.is_dir():
                    count = len(list(item.glob('**/*')))
                    metadata["content"].append({
                        "name": item.name,
                        "type": "directory",
                        "item_count": count
                    })
                elif item.is_file():
                    metadata["content"].append({
                        "name": item.name,
                        "type": "file",
                        "size": item.stat().st_size,
                        "size_human": self._human_readable_size(item.stat().st_size)
                    })
            
            # Save metadata
            async with aiofiles.open(backup_dir / "metadata.json", 'w') as f:
                await f.write(json.dumps(metadata, indent=2))
                
            self.logger.info("Backup metadata generated successfully")
            return metadata
            
        except Exception as e:
            self.logger.error(f"Failed to generate backup metadata: {str(e)}")
            return {}
            
    async def create_backup_log(self, backup_dir: Path) -> str:
        """Create a readable log file of the backup process"""
        try:
            log_path = backup_dir / "backup.log"
            
            # Collect log entries for this backup operation
            log_entries = []
            for handler in self.logger.handlers:
                if isinstance(handler, logging.handlers.MemoryHandler):
                    log_entries = handler.buffer
                    
            if not log_entries:
                # Try to get logs from file handlers
                for handler in self.logger.handlers:
                    if isinstance(handler, logging.FileHandler):
                        log_file = handler.baseFilename
                        if os.path.exists(log_file):
                            async with aiofiles.open(log_file, 'r') as f:
                                log_content = await f.read()
                                log_lines = log_content.splitlines()
                                
                                # Filter logs related to this backup
                                backup_name = backup_dir.name
                                filtered_logs = [line for line in log_lines if backup_name in line]
                                log_entries = filtered_logs
            
            # Format log entries
            formatted_logs = []
            for entry in log_entries:
                if isinstance(entry, logging.LogRecord):
                    formatted_logs.append(f"{entry.asctime} [{entry.levelname}] {entry.message}")
                else:
                    formatted_logs.append(str(entry))
                    
            # Write log file
            async with aiofiles.open(log_path, 'w') as f:
                await f.write("\n".join(formatted_logs))
                
            self.logger.info(f"Backup log created at {log_path}")
            return str(log_path)
            
        except Exception as e:
            self.logger.error(f"Failed to create backup log: {str(e)}")
            return ""
            
    def is_supported_android_version(self) -> bool:
        """Check if the device's Android version is supported"""
        try:
            version = self.device_info.android_version
            if not version:
                return False
                
            # Extract major version
            major_version = int(version.split('.')[0])
            
            # Support Android 6.0 (API 23) or higher
            return major_version >= 6
        except Exception:
            return False

    async def secure_delete(self, file_path: Path) -> bool:
        """Securely delete a file by overwriting with random data"""
        try:
            if not file_path.exists():
                return True
                
            # Get file size
            size = file_path.stat().st_size
            
            # Open file and overwrite with random data multiple times
            for i in range(3):  # Standard DoD approach uses 3 passes
                with open(file_path, 'wb') as f:
                    # First pass: zeros
                    if i == 0:
                        f.write(b'\x00' * min(1024 * 1024, size))  # Write in 1MB chunks max
                        f.seek(0)
                    # Second pass: ones
                    elif i == 1:
                        f.write(b'\xFF' * min(1024 * 1024, size))
                        f.seek(0)
                    # Third pass: random data
                    else:
                        f.write(os.urandom(min(1024 * 1024, size)))
                        f.seek(0)
                        
            # Finally delete the file
            file_path.unlink()
            return True
            
        except Exception as e:
            self.logger.error(f"Secure delete failed: {str(e)}")
            return False
            
    def get_estimated_time_remaining(self) -> Dict:
        """Calculate estimated time remaining for current backup/restore operation"""
        result = {
            "percent_complete": 0,
            "elapsed_seconds": 0,
            "estimated_total_seconds": 0,
            "estimated_remaining_seconds": 0,
            "formatted_remaining": "Unknown"
        }
        
        if not self._start_time:
            return result
            
        # Calculate elapsed time
        elapsed = (datetime.now() - self._start_time).total_seconds()
        result["elapsed_seconds"] = int(elapsed)
        
        # Calculate completion percentage
        if not self._progress or self._progress['total'] == 0:
            return result
            
        completed = len(self._progress.get('completed', []))
        total = self._progress.get('total', 0)
        
        percent = min(100, int((completed / max(1, total)) * 100))
        result["percent_complete"] = percent
        
        # Estimate remaining time
        if percent > 0:
            estimated_total = elapsed * 100 / percent
            remaining = estimated_total - elapsed
            
            result["estimated_total_seconds"] = int(estimated_total)
            result["estimated_remaining_seconds"] = int(remaining)
            
            # Format remaining time
            if remaining < 60:
                result["formatted_remaining"] = f"{int(remaining)} seconds"
            elif remaining < 3600:
                result["formatted_remaining"] = f"{int(remaining / 60)} minutes"
            else:
                hours = int(remaining / 3600)
                minutes = int((remaining % 3600) / 60)
                result["formatted_remaining"] = f"{hours}h {minutes}m"
                
        return result
        
    async def create_self_extracting_backup(self, backup_path: Path) -> Path:
        """Create a self-extracting backup script for non-technical users"""
        try:
            # Check if backup exists
            if not backup_path.exists():
                raise FileNotFoundError(f"Backup file not found: {backup_path}")
                
            # Create output path
            output_path = backup_path.with_suffix('.self_extract.py')
            
            # Read backup file into memory (for small backups only)
            with open(backup_path, 'rb') as f:
                backup_data = f.read()
                
            # Create self-extracting Python script
            script_template = f'''#!/usr/bin/env python3
import base64
import os
import sys
import tarfile
import tempfile
from pathlib import Path

BACKUP_DATA = """
{base64.b64encode(backup_data).decode()}
"""

def extract_backup():
    print("Android Backup Self-Extractor")
    print("============================")
    
    # Decode backup data
    backup_data = base64.b64decode(BACKUP_DATA)
    
    # Create temporary file
    temp_dir = tempfile.gettempdir()
    temp_file = os.path.join(temp_dir, "backup_temp.tar.gz")
    
    with open(temp_file, "wb") as f:
        f.write(backup_data)
    
    # Extract backup
    extract_dir = os.path.join(os.getcwd(), "extracted_backup")
    os.makedirs(extract_dir, exist_ok=True)
    
    with tarfile.open(temp_file, "r:gz") as tar:
        tar.extractall(path=extract_dir)
    
    # Clean up temp file
    os.unlink(temp_file)
    
    print(f"Backup extracted to: {extract_dir}")
    print("Done!")

if __name__ == "__main__":
    extract_backup()
'''
            
            # Write script to file
            async with aiofiles.open(output_path, 'w') as f:
                await f.write(script_template)
                
            # Make executable
            os.chmod(output_path, 0o755)
            
            self.logger.info(f"Self-extracting backup created: {output_path}")
            return output_path
            
        except Exception as e:
            self.logger.error(f"Failed to create self-extracting backup: {str(e)}")
            return None
            
    async def send_backup_notification(self, title: str, message: str):
        """Send notification on backup completion based on platform"""
        try:
            if self.platform == 'windows':
                # Windows notification
                from win10toast import ToastNotifier
                toaster = ToastNotifier()
                toaster.show_toast(title, message, duration=10)
                
            elif self.platform == 'linux':
                # Check if notify-send is available
                notify_cmd = shutil.which('notify-send')
                if notify_cmd:
                    subprocess.run([notify_cmd, title, message])
                    
            elif self.platform == 'darwin':  # macOS
                # Use AppleScript for notification
                script = f'display notification "{message}" with title "{title}"'
                subprocess.run(['osascript', '-e', script])
                
            self.logger.info(f"Notification sent: {title}")
            
        except Exception as e:
            self.logger.warning(f"Failed to send notification: {str(e)}")
            
    async def verify_backup_integrity(self, backup_path: Path) -> Dict:
        """Verify the integrity of a backup file"""
        result = {
            "valid": False,
            "errors": [],
            "warnings": []
        }
        
        try:
            if not backup_path.exists():
                result["errors"].append("Backup file does not exist")
                return result
                
            # Check metadata
            metadata_path = backup_path.with_suffix('.json')
            if not metadata_path.exists():
                result["errors"].append("Metadata file missing")
                return result
                
            # Load metadata
            async with aiofiles.open(metadata_path, 'r') as f:
                metadata = json.loads(await f.read())
                
            # Check manifest
            if 'manifest' not in metadata:
                result["warnings"].append("No manifest found in metadata")
                
            # Check if encrypted backup has salt
            if metadata.get('encrypted', False) and not metadata.get('salt'):
                result["warnings"].append("Encrypted backup missing salt information")
                
            # For non-encrypted backups, check content
            if not metadata.get('encrypted', False):
                # Extract to temporary directory
                temp_dir = await self._extract_backup(backup_path)
                
                try:
                    # Check for essential files
                    if not (temp_dir / 'device_info.json').exists():
                        result["warnings"].append("Missing device info file")
                        
                    # Check manifest if available
                    if 'manifest' in metadata:
                        # Verify files against manifest
                        for file_path, file_hash in metadata['manifest'].items():
                            check_path = temp_dir / file_path
                            if not check_path.exists():
                                result["errors"].append(f"File missing: {file_path}")
                                continue
                                
                            # Check hash
                            actual_hash = hashlib.sha256(check_path.read_bytes()).hexdigest()
                            if actual_hash != file_hash:
                                result["errors"].append(f"Hash mismatch: {file_path}")
                finally:
                    # Clean up temporary directory
                    shutil.rmtree(temp_dir, ignore_errors=True)
            
            # Set validity based on errors
            result["valid"] = len(result["errors"]) == 0
            return result
            
        except Exception as e:
            result["errors"].append(f"Verification error: {str(e)}")
            self.logger.error(f"Backup verification failed: {str(e)}")
            return result
            
    async def check_permissions(self) -> Dict:
        """Check required permissions for backup operations"""
        result = {
            "has_adb_access": False,
            "has_root": False,
            "has_backup_permission": False,
            "missing_permissions": []
        }
        
        try:
            # Check ADB connection
            try:
                if not self.device:
                    await self._init_device()
                result["has_adb_access"] = True
            except Exception:
                result["has_adb_access"] = False
                result["missing_permissions"].append("ADB connection failed")
                
            # Check root access
            if self.device_info:
                result["has_root"] = self.device_info.is_rooted
            if not result.get("has_root"):
                result["missing_permissions"].append("Root access not available")
                
            # Check backup permission (Android 9+)
            if self.device_info and int(self.device_info.sdk_version) >= 28:
                cmd_result = await self.device.shell("dumpsys package android | grep BACKUP")
                result["has_backup_permission"] = "ALLOW_BACKUP" in cmd_result
                
                if not result["has_backup_permission"]:
                    result["missing_permissions"].append("ALLOW_BACKUP permission not granted")
            else:
                # Older Android versions don't need explicit permission
                result["has_backup_permission"] = True
                
            return result
            
        except Exception as e:
            self.logger.error(f"Permission check failed: {str(e)}")
            result["missing_permissions"].append(f"Error checking permissions: {str(e)}")
            return result

    async def encrypt_file(self, input_path: Path, output_path: Path) -> bool:
        """Encrypt a file using the configured encryption settings"""
        if not self.fernet:
            self.logger.warning("Encryption not configured, file will not be encrypted")
            shutil.copy2(input_path, output_path)
            return True
            
        try:
            # Read file in chunks to handle large files
            with open(input_path, 'rb') as in_file, open(output_path, 'wb') as out_file:
                # First write the salt for decryption later
                out_file.write(self.encryption_salt)
                
                # Encrypt in chunks
                while chunk := in_file.read(self.config.chunk_size):
                    encrypted_chunk = self.fernet.encrypt(chunk)
                    out_file.write(encrypted_chunk)
                    
            self.logger.info(f"File encrypted successfully: {output_path}")
            return True
            
        except Exception as e:
            self.logger.error(f"Encryption failed: {str(e)}")
            return False
            
    async def decrypt_file(self, input_path: Path, output_path: Path, password: str) -> bool:
        """Decrypt a file using the provided password"""
        try:
            with open(input_path, 'rb') as in_file:
                # Read the salt (first 16 bytes)
                salt = in_file.read(16)
                
                # Derive key from password and salt
                kdf = PBKDF2HMAC(
                    algorithm=hashes.SHA512(),
                    length=32,
                    salt=salt,
                    iterations=self.config.pbkdf2_iterations,
                    backend=default_backend()
                )
                key = base64.urlsafe_b64encode(kdf.derive(password.encode()))
                fernet = Fernet(key)
                
                # Decrypt in chunks
                with open(output_path, 'wb') as out_file:
                    while chunk := in_file.read(self.config.chunk_size + 16):  # Account for Fernet overhead
                        try:
                            decrypted_chunk = fernet.decrypt(chunk)
                            out_file.write(decrypted_chunk)
                        except Exception as e:
                            self.logger.error(f"Decryption error: {str(e)}")
                            return False
                            
            self.logger.info(f"File decrypted successfully: {output_path}")
            return True
            
        except Exception as e:
            self.logger.error(f"Decryption failed: {str(e)}")
            return False
    
    def _human_readable_size(self, size_bytes: int) -> str:
        """Convert bytes to human-readable size format"""
        if size_bytes < 1024:
            return f"{size_bytes} B"
        elif size_bytes < 1024 * 1024:
            return f"{size_bytes / 1024:.1f} KB"
        elif size_bytes < 1024 * 1024 * 1024:
            return f"{size_bytes / (1024 * 1024):.1f} MB"
        else:
            return f"{size_bytes / (1024 * 1024 * 1024):.2f} GB"
            
    async def _get_storage_free(self) -> int:
        """Get free storage space on device"""
        try:
            df_output = await self.device.shell("df /data")
            lines = df_output.strip().split('\n')
            if len(lines) >= 2:
                parts = lines[1].split()
                if len(parts) >= 4:
                    # Free space in KB, convert to bytes
                    return int(parts[3]) * 1024
            return 0
        except Exception:
            return 0
            
    async def _execute_adb_command(self, cmd: str, as_root: bool = False) -> str:
        """Execute an ADB shell command with root if requested and available"""
        try:
            if as_root and self.device_info.is_rooted:
                return await self.device.shell(f"su -c '{cmd}'")
            else:
                return await self.device.shell(cmd)
        except Exception as e:
            self.logger.error(f"ADB command failed: {str(e)}")
            raise
                async def optimize_backup_size(self, backup_path: Path) -> int:
        """Optimize backup size by removing unnecessary files"""
        try:
            total_saved = 0
            
            # Find and remove unnecessary files
            patterns_to_remove = [
                "*/cache/*",
                "*/code_cache/*",
                "*/*.log",
                "*/tmp/*",
                "*/thumbnails/*"
            ]
            
            for pattern in patterns_to_remove:
                matching_files = backup_path.glob(pattern)
                for file_path in matching_files:
                    if file_path.is_file():
                        size = file_path.stat().st_size
                        file_path.unlink()
                        total_saved += size
                    elif file_path.is_dir():
                        size = sum(f.stat().st_size for f in file_path.glob('**/*') if f.is_file())
                        shutil.rmtree(file_path)
                        total_saved += size
                        
            self.logger.info(f"Optimization complete, saved {self._human_readable_size(total_saved)}")
            return total_saved
            
        except Exception as e:
            self.logger.error(f"Failed to optimize backup size: {str(e)}")
            return 0
    
    async def _create_backup_dir(self) -> Path:
        """Create a uniquely named backup directory"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        device_name = self.device_info.model.replace(" ", "_")
        backup_name = f"backup_{device_name}_{timestamp}"
        backup_dir = self.backup_root / backup_name
        
        os.makedirs(backup_dir, exist_ok=True)
        os.makedirs(backup_dir / "apps", exist_ok=True)
        os.makedirs(backup_dir / "data", exist_ok=True)
        
        self.logger.info(f"Created backup directory: {backup_dir}")
        return backup_dir
    
    async def _encrypt_file(self, source_path: Path, dest_path: Path):
        """Encrypt file using configured encryption settings"""
        if not self.fernet:
            shutil.copy2(source_path, dest_path)
            return
        
        async with aiofiles.open(source_path, 'rb') as source:
            data = await source.read()
        
        encrypted_data = self.fernet.encrypt(data)
        
        async with aiofiles.open(dest_path, 'wb') as dest:
            await dest.write(encrypted_data)
    
    async def _backup_system_data(self, backup_dir: Path):
        """Backup critical system data if rooted"""
        if not self.device_info.is_rooted:
            return
        
        system_dir = backup_dir / "system"
        os.makedirs(system_dir, exist_ok=True)
        
        # Backup system settings
        settings_db = "/data/data/com.android.providers.settings/databases/settings.db"
        temp_path = "/data/local/tmp/settings.db"
        
        try:
            # Copy to accessible location
            await self._execute_adb_command(f"cp {settings_db} {temp_path}", as_root=True)
            await self._execute_adb_command(f"chmod 644 {temp_path}", as_root=True)
            
            # Pull file
            await self.device.pull(temp_path, system_dir / "settings.db")
            
            # Clean up
            await self._execute_adb_command(f"rm {temp_path}", as_root=True)
            
            self.logger.info("System settings backed up successfully")
        except Exception as e:
            self.logger.error(f"Failed to backup system settings: {str(e)}")
    
    def parse_size_str(self, size_str: str) -> int:
        """Parse human-readable size string to bytes"""
        try:
            if "KB" in size_str:
                return int(float(size_str.replace(" KB", "")) * 1024)
            elif "MB" in size_str:
                return int(float(size_str.replace(" MB", "")) * 1024 * 1024)
            elif "GB" in size_str:
                return int(float(size_str.replace(" GB", "")) * 1024 * 1024 * 1024)
            elif "B" in size_str:
                return int(float(size_str.replace(" B", "")))
        except Exception:
            return 0


def main():
    """Main entry point with CLI and GUI options."""
    parser = argparse.ArgumentParser(description="Ultimate Android Backup Solution")
    parser.add_argument('--action', choices=['backup', 'restore'], help="Action to perform")
    parser.add_argument('--file', help="Backup file for restore")
    parser.add_argument('--password', help="Encryption password")
    parser.add_argument('--cloud', action='store_true', help="Enable cloud backup")
    parser.add_argument('--gui', action='store_true', help="Launch GUI interface")

    args = parser.parse_args()

    # Check for GUI mode
    if args.gui:
        # GUI mode
        root = tk.Tk()
        gui = BackupGUI(root)
        root.mainloop()
        return

    # Command-line mode
    cloud_config = None
    if args.cloud:
        # Get cloud credentials from keyring or prompt user
        try:
            access_token = keyring.get_password("android_backup", "access_token")
            refresh_token = keyring.get_password("android_backup", "refresh_token")
            
            if not access_token or not refresh_token:
                print("Cloud backup enabled but credentials not found.")
                print("Please enter your cloud credentials:")
                access_token = input("Access Token: ")
                refresh_token = input("Refresh Token: ")
                
                # Save to keyring
                keyring.set_password("android_backup", "access_token", access_token)
                keyring.set_password("android_backup", "refresh_token", refresh_token)
                
            cloud_config = {
                'base_url': "https://mittcloud.tele2.se",
                'access_token': access_token,
                'refresh_token': refresh_token
            }
        except Exception as e:
            print(f"Error setting up cloud config: {str(e)}")
            cloud_config = None

    backup = UltimateAndroidBackup(password=args.password, cloud_config=cloud_config)
    
    try:
        if args.action == 'backup':
            backup_path = asyncio.run(backup.backup())
            print(f"Backup completed successfully: {backup_path}")
            
        elif args.action == 'restore':
            if not args.file:
                print("Error: Restore action requires --file argument")
                sys.exit(1)
                
            asyncio.run(backup.restore(Path(args.file), args.password))
            print("Restore completed successfully")
            
        else:
            print("No action specified. Use --action backup|restore or --gui")
            
    except Exception as e:
        print(f"Error: {str(e)}")
        sys.exit(1)


if __name__ == '__main__':
    main()                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        