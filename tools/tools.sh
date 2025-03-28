#!/system/bin/sh
if [ "$(whoami)" != root ]; then
echo "Are you stupid? If you don't give me root, you're going to crawl"
exit 1
fi
[[ -d /data/cache ]] && set -x 2> /data/cache/debug_output.log
shell_language="zh-TW"
MODDIR="$MODDIR"
MODDIR_NAME="${MODDIR##*/}"
tools_path="$MODDIR/tools"
script="${0##*/}"
backup_version="202412282251"
[[ $SHELL = *mt* ]] && echo "Do not use the MT Manager expansion package environment, please change the system environment" && exit 2
update_backup_settings_conf() {
echo "#0Turn off the volume key selection (If the option is not set, force the volume key selection)
#1 Turn on the volume key selection (If the option is set, skip the option prompt)
#2 Use keyboard input, applicable to devices without volume keys (If the option is not set, force the keyboard input)
Lo="${Lo:-0}"

#Background script execution
0 The current terminal cannot be closed, there is a compression rate
1 The terminal may not display at all, but the log will continue to refresh, and the terminal can be completely closed directly
background_execution="${background_execution:-0}"

#Script language setting Leave it blank to automatically identify the system language environment and translate
#1Simplified Chinese 0Traditional Chinese
Shell_LANG="$Shell_LANG"

#Pretend to light up the screen after backup starts
#1Enable 0Disable
setDisplayPowerMode="${setDisplayPowerMode:-0}"

#Customize the backup file output location. Support relative path (leave blank to default to current path)
Output_path=\""$Output_path"\"

#Customize applist.txt location. Support relative path (leave blank to default to current path)
list_location=\""$list_location"\"

#Automatically update scripts (leave blank to force selection)
#1Enable 0Disable
update="${update:-1}"

#Customize shielding of external mount points. For example: OTG, virtual SD, etc. For multiple mount points, please use | Segmentation
#After blocking, the volume button selection will not be prompted, and the external storage location specified by Output_path will not be affected
mount_point=\""${mount_point:-rannki|0000-1}"\"

#User (such as 0 999, etc. If there are multiple users, leave it blank and force selection. If there are no multiple users, the default user 0 will not be asked)
user="$user"

#Backup mode
#1 includes data + installation package, 0 only includes installation package
#When this option is set to 1, Backup_obb_data, Backup_user_data, and blacklist_mode will be available When 0, the Backup_user_data, Backup_obb_data, and blacklist_mode options are not effective.
# In addition, when set to 0, appList.txt will be ignored! and any blacklist settings (including blacklists)
Backup_Mode="${Backup_Mode:-1}"

# Output the card flash package for recovery rescue when executing Generate Application List.sh?
#1 output 0 do not output
recovery_flash="${recovery_flash:-0}"

#Whether to back up user data (1 backup 0 do not backup leave blank for mandatory selection)
Backup_user_data="${Backup_user_data:-1}"

#Whether to back up external data Example: Genshin Impact data package (1 backup 0 do not backup leave blank for mandatory selection)
Backup_obb_data="${Backup_obb_data:-1}"

#Whether to back up a custom directory after application data backup is completed
#1 open 0 off
backup_media="${backup_media:-0}"

# Ignore backup if there is a process (1 ignores 0 backup)
Background_apps_ignore="${Background_apps_ignore:-0}"

# If you encounter abnormal list output, please set this to 1
debug_list="${debug_list:-0}"

# Add a custom backup path, for example: Download DCIM and other folders Please use the absolute path, do not delete \"\"
Custom_path=\""${Custom_path:-
/storage/emulated/0/Pictures/
/storage/emulated/0/Download/
/storage/emulated/0/Music
/storage/emulated/0/DCIM/
/data/adb
}"\"

#Blacklist mode (1 completely ignored, no backup 0 Only backup the installation package, note! This option can only be used when Backup_Mode=1)
blacklist_mode="${blacklist_mode:-0}"

#Backup blacklist (backup strategy is controlled by "blacklist mode", here is only used as a blacklist application list)
blacklist=\""${blacklist:-
#com.esunbank
#com.chailease.tw.app.android.ccfappcust}"\"

#Pre-installed application whitelist in data Example: Album Recorder Weather Calculator, etc. (pre-installed apps are blocked by default. If you need to back up, please add pre-installed apps to the whitelist)
whitelist=\""${whitelist:-
com.xiaomi.xmsf
com.xiaomi.xiaoailite
com.xiaomi.hm.health
com.duokan.phone.remotecontroller
com.miui.weather2
com.milink.service
com.android.soundrecorder
com.miui.virtualsim
com.xiaomi.vipaccount
com.miui.fm
com.xiaomi.shop
com.xiaomi.smarthome
com.miui.notes
com.xiaomi.router
com.xiaomi.mico
dev.miuiicons.pedroz}"\"

#Can be backed up System application whitelist for backup (default system application is blocked, if you need to backup, please add system application whitelist)
system=\""${system:-
com.google.android.calendar
com.google.android.gm
com.google.android.googlequicksearchbox
com.google.android.tts
com.google.android.apps.maps
com.google.android.apps.messaging
com.google.android.inputmethod.latin
com.instagram.android
com.facebook.orca
sh.siava.AOSPMods
com.facebook.katana
com.android.chrome}"\"

#Compression algorithm (zstd can be used tar, tar is only for packaging. If you have any good compression algorithms, please contact me.
#zstd has good compression rate and speed
Compression_method=${Compression_method:-zstd}

#Main color
rgb_a="${rgb_a:-226}"
#Secondary color
rgb_b="${rgb_b:-123}"
rgb_c="${rgb_c:-177}"
" | sed '
/^Custom_path/ s/ /\n/g;
/^blacklist/ s/ /\n/g;
/^whitelist/ s/ /\n/g;
/^system/ s/ /\n/g;
/^am_start/ s/ /\n/g;
s/true/1/g;
s/false/0/g'
}
update_Restore_settings_conf() {
echo "#0 Turn off volume key selection (if option is not set, force volume key selection)
#1 Turn on volume key selection (if option is set, skip the option prompt)
#2 Use keyboard input, suitable for device selection without volume key (If the option is not set, keyboard input is forced)
Lo="${Lo:-0}"

#Background script execution
0 The current terminal cannot be closed, there is compression rate
1 The terminal may not display at all, but the log will continue to refresh, and the terminal can be completely closed directly
background_execution="${background_execution:-0}"

# Pretend to light up the screen after recovery starts
#1 Turn on 0 Turn off
setDisplayPowerMode="${setDisplayPowerMode:-0}"

# Script language setting Empty Automatically translate for the current system language environment
#1 Simplified Chinese 0Traditional Chinese
Shell_LANG="$Shell_LANG"

#Automatically update scripts (leave blank to force selection)
update="${update:-1}"

#Recovery mode (1 to restore uninstalled applications 0 to restore everything)
recovery_mode="${recovery_mode:-0}"

#Recover Magisk module
modules_recovery="${modules_recovery:-0}"

#Recover folder
media_recovery="${media_recovery:-0}"

#Ignore recovery of existing processes (1 to ignore 0 to restore)
Background_apps_ignore="${Background_apps_ignore:-0}"

#User (such as 0 999 and other users, leave it blank if there are multiple users to force the volume key selection, if there are no multiple users, the default is 0 and no inquiry)
user=

#Primary color
rgb_a="${rgb_a:-226}"
#Secondary color
rgb_b="${rgb_b:-123}"
rgb_c="${rgb_c:-177}"" | sed 's/true/1/g ; s/false/0/g'
}
if [[ ! -d $tools_path ]]; then
tools_path="${MODDIR%/*}/tools"
[[ ! -d $tools_path ]] && echo "$tools_path binary directory missing" && EXIT="true"
fi
if [[ ! -f $conf_path ]]; then
case $operate in
backup_media|backup|Getlist|Restore|Restore2|check_file|convert|Restore3|dumpname)
if [[ $conf_path != *Backup_* ]]; then
update_backup_settings_conf>"$conf_path"
echo "Because the script cannot find\n$conf_path\n, the default list is regenerated\nPlease reconfigure and re-execute the script" && exit 0
else
if [[ $conf_path = *Backup_* ]]; then
update_Restore_settings_conf>"$conf_path"
echo "Because the script cannot find\n$conf_path\n, the default list is regenerated\nPlease reconfigure and re-execute the script" && exit 0
else
echo "$conf_path configuration is missing" && exit 1
fi
fi ;;
esac
fi
[[ ! -f $conf_path ]] && echo "$conf_path is missing" && exit 2
. "$conf_path" &>/dev/null
case $operate in
backup_media|backup|Getlist|Restore|Restore2|check_file|convert|Restore3|dumpname)
    if [[ $conf_path != *Backup_* ]]; then
        update_backup_settings_conf>"$conf_path"
    else
        if [[ $conf_path = *Backup_* ]]; then
            update_Restore_settings_conf>"$conf_path"
        else
            echo "$conf_path configuration is missing" && exit 1
        fi
    fi ;;
esac
if [[ $Shell_LANG != "" ]]; then
case $Shell_LANG in
1) LANG="CN" ;;
0) LANG="TW" ;;
*) echo "$conf_path Shell_LANG=$Shell_LANG setting error correct 1or0" && exit 2 ;;
esac
fi
LANG="${LANG:="$(getprop "persist.sys.locale")"}"
echoRgb() {
#Convert echo color to improve readability
if [[ $2 = 0 ]]; then
echo -e "\e[38;5;197m -$1\e[0m"
elif [[ $2 = 1 ]]; then
echo -e "\e[38;5;121m -$1\e[0m"
elif [[ $2 = 2 ]]; then
echo -e "\e[38;5;${rgb_c}m -$1\e[0m"
elif [[ $2 = 3 ]]; then
echo -e "\e[38;5;${rgb_b}m -$1\e[0m"
else
echo -e "\e[38;5;${rgb_a}m -$1\e[0m"
fi
}
rgb_a="${rgb_a:=214}"
abi="$(getprop ro.product.cpu.abi)"
case $abi in
arm64*)
if [[ $(getprop ro.build.version.sdk) -lt 24 ]]; then
echoRgb "Device Android $(getprop ro.build.version.release) version is too low. Please upgrade to Android 8+" "0"
exit 1
else
case $(getprop ro.build.version.sdk) in
26|27|28)
echoRgb "Device Android $(getprop ro.build.version.release) version is too low, can not determine the script can be used correctly" "0"
;;
esac
fi
;;
*)
echoRgb "Unknown architecture: $abi" "0"
exit 1
;;
esac
PATH="/sbin/.magisk/busybox:/sbin/.magisk:/sbin:/data/adb/ksu/bin:/system_ext/bin:/system/bin:/system/xbin:/vendor/bin:/vendor/xbin:/data/data/com.omarea.vtools/files/toolkit:/data/user/0/com.termux/files/usr/bin"
if [[ -d $(magisk --path 2>/dev/null) ]]; then
	PATH="$(magisk --path 2>/dev/null)/.magisk/busybox:$PATH"
else
	[[ $(ksud -V 2>/dev/null) = "" ]] && echo "Magisk busybox Path does not exist"
fi
export PATH="$PATH"
#tools_path="${tools_path/'/storage/emulated/'/'/data/media/'}"
filepath="/data/backup_tools"
busybox="$filepath/busybox"
busybox2="$tools_path/busybox"
#exclude self
exclude="
update
soc.json
update-binary
classes.dex
Device_List"
if [[ ! -d $filepath ]]; then
	mkdir -p "$filepath"
	[[ $? = 0 ]] && echoRgb "Set up busybox environment"
fi
#Delete invalid soft links
find -L "$filepath" -maxdepth 1 -type l -exec rm -rf {} \;
if [[ -f $busybox && -f $busybox2 ]]; then
filesha256="$(sha256sum "$busybox" | cut -d" " -f1)"
filesha256_1="$(sha256sum "$busybox2" | cut -d" " -f1)"
if [[ $filesha256 != $filesha256_1 ]]; then
echoRgb "busybox sha256 is inconsistent. Recreate the environment"
rm -rf "$filepath"/*
fi
fi
find "$tools_path" -maxdepth 1 ! -path "$tools_path/tools.sh" -type f | egrep -v "$(echo $exclude | sed 's/ /\|/g')" | while read; do
	File_name="${REPLY##*/}"
	if [[ ! -f $filepath/$File_name ]]; then
		cp -r "$REPLY" "$filepath"
		chmod 0777 "$filepath/$File_name"
		echoRgb "$File_name > $filepath/$File_name"
	else
		filesha256="$(sha256sum "$filepath/$File_name" | cut -d" " -f1)"
		filesha256_1="$(sha256sum "$tools_path/$File_name" | cut -d" " -f1)"
		if [[ $filesha256 != $filesha256_1 ]]; then
			echoRgb "$File_name sha256 is inconsistent Recreate"
			cp -r "$REPLY" "$filepath"
			chmod 0777 "$filepath/$File_name"
			echoRgb "$File_name > $filepath/$File_name"
		fi
	fi
done
if [[ -f $busybox ]]; then
	"$busybox" --list | while read; do
		if [[ $REPLY != tar && $REPLY != bc && ! -f $filepath/$REPLY ]]; then
			ln -fs "$busybox" "$filepath/$REPLY"
		fi
	done
fi
[[ ! -f $filepath/zstd ]] && echoRgb "$filepath is missing zstd" && exit 2
export PATH="$filepath:$PATH"
export TZ=Asia/Taipei
export CLASSPATH="$tools_path/classes.dex"
quit=0
while read -r file expected_hash; do
  if [[ -f $tools_path/$file ]]; then
    computed_hash="$(sha256sum "$tools_path/$file" | awk '{print $1}')"
    if [[ $computed_hash = $expected_hash ]]; then
      echoRgb "✅ $file: Verification passed"
    else
      echoRgb "❌ $tools_path/$file: SHA-256 inconsistent"
      quit=2
      break
    fi
  else
    echoRgb "⚠️ File $tools_path/$file does not exist"
    quit=1
    break
  fi
done <<< "$(cat <<EOF
zstd 2388211eb3960070c6b4528f68f7129a9ef5d165a0fef0113ac59e723006f4ca
tar 3c605b1e9eb8283555225dcad4a3bf1777ae39c5f19a2c8b8943140fd7555814
classes.dex 0057136d4da6c0a3d1bb3e67c9cd845acaed183217a9dfee423a05a3d30121ab
bc b15d730591f6fb52af59284b87d939c5bea204f944405a3518224d8df788dc15
busybox 4d60ab3f5a59ebb2ca863f2f514e6924401b581e9b64f602665c008177626651
find 7fa812e58aafa29679cf8b50fc617ecf9fec2cfb2e06ea491e0a2d6bf79b903b
jq 4dd2d8a0661df0b22f1bb9a1f9830f06b6f3b8f7d91211a1ef5d7c4f06a8b4a5
keycheck 50645ee0e0d2a7d64fb4a1286446df7a4445f3d11aefd49eeeb88515b314c363
zip d9015b3c5d3376a4f9f2d204afd2aeaa4a86fd0174da1be090e41622e73be0ec
EOF)"
if [[ $background_execution = 1 || $setDisplayPowerMode = 1 ]]; then
    alias notification="app_process /system/bin com.xayah.dex.NotificationUtil notify -t 'SpeedBackup' "$@""
else
alias notification="&>/dev/null"
fi
if [[ $quit -ne 0 ]]; then
exit "$quit"
fi
sleep 1 && clear
TMPDIR="/data/local/tmp"
rm -rf "$TMPDIR"/*
[[ ! -d $TMPDIR ]] && mkdir "$TMPDIR"
chmod 771 "$TMPDIR"
chown '2000:2000' "$TMPDIR"
if [[ $(which busybox) = "" ]]; then
echoRgb "No busybox found in the environment variable. Please add a \narm64 available busybox in tools\nor install the machine assistant scene or Magisk busybox module...." "0"
exit 1
fi
if [[ $(which toybox | egrep -o "system") != system ]]; then
echoRgb "Toybox not found in system variables" "0"
exit 1
fi
#The following is a custom function
alias down="app_process /system/bin com.xayah.dex.HttpUtil get $@"
case $LANG in
*CN* | *cn*)
alias ts="app_process /system/bin com.xayah.dex.CCUtil t2s $@" ;;
*)
alias ts="app_process /system/bin com.xayah.dex.CCUtil s2t $@" ;;
esac
alias LS="toybox ls -Zd"
Set_back_0() {
return 0
}
Set_back_1() {
return 1
}
endtime() {
#Calculate the total switching time consumption
case $1 in
1) starttime="$starttime1" ;;
2) starttime="$starttime2" ;;
esac
endtime="$(date -u "+%s")"
duration="$(echo $((endtime - starttime)) | awk '{t=split("60 seconds 60 minutes 24 hours 999 days",a);for(n=1;n<t;n+=2){if($1==0)break;s=$1%a[n]a[n+1]s;$1=int($1/a[n])}print s}')"
[[ $duration != "" ]] && echo " -$2 takes:$duration" || echo " -$2 takes:0 seconds"
}
nskg=1
get_version() {
while :; do
keycheck
case $? in
42)
[[ $Select_user = true ]] && branch="$1" || branch=true
echoRgb "$1" "1"
;;
41)
[[ $Select_user = true ]] && branch="$2" || branch=false
echoRgb "$2" "0"
;;
*)
echoRgb "keycheck error" "0"
continue
;;
esac
sleep 0.5
break
done
}
isBoolean() {
nsx="$1"
if [[ $1 = 1 ]]; then
nsx=true
elif [[ $1 = 0 ]]; then
nsx=false
else
echoRgb "$conf_path $2=$1 is incorrectly filled in, the correct value is 1or0" "0"
exit 2
fi
}
echo_log() {
if [[ $? = 0 ]]; then
echoRgb "$1 succeeded" "1"
result=0
Set_back_0
else
echoRgb "$1 failed, died" "0"
notification "$RANDOM" "$name1: $1 failed, died"
result=1
Set_back_1
fi
}
process_name() {
pgrep -f "$1" | while read; do
kill -KILL "$REPLY" 2>/dev/null
done
}
kill_Serve() {
{
if [[ -e $TMPDIR/scriptTMP ]]; then
scriptname="$(cat "$TMPDIR/scriptTMP")"
echoRgb "Script leftover process, will be killed and then exit the script, please re-execute it\n - kill $scriptname" "0"
rm -rf "$TMPDIR/scriptTMP"
		process_name "$scriptname"
		exit
	fi
	} &
	wait
}
Show_boottime() {
	awk -F '.' '{run_days=$1 / 86400;run_hour=($1 % 86400)/3600;run_minute=($1 % 3600)/60;run_second=$1 % 60;printf("%d day %d hour %d minute %d second",run_days,run_hour,run_minute,run_second)}' /proc/uptime 2>/dev/null
}
[[ -f /sys/block/sda/size ]] && ROM_TYPE="UFS" || ROM_TYPE="eMMC"
if [[ -f /proc/scsi/scsi ]]; then
	UFS_MODEL="$(sed -n 3p /proc/scsi/scsi | awk '/Vendor/{print $2,$4}')"
else
	if [[ $(cat "/sys/class/block/sda/device/inquiry" 2>/dev/null) != "" ]]; then
		UFS_MODEL="$(cat "/sys/class/block/sda/device/inquiry")"
	else
		UFS_MODEL="unknown"
	fi
fi
[[ $(egrep -w "$(getprop ro.product.model 2>/dev/null)" "$tools_path/Device_List" | awk -F'"' '{print $4}') != "" ]] && Device_name="$(egrep -w "$(getprop ro.product.model 2>/dev/null)" "$tools_path/Device_List" | awk -F'"' '{print $4}' | head -1)" || Device_name="$(getprop ro.product.model 2>/dev/null)"
if [[ $(su -v 2>/dev/null) != "" ]]; then
    Manager_version="$(su -v 2>/dev/null)"
    [[ $Manager_version = *KernelSU* ]] && ksu="ksu"
    [[ $ksu = "" ]] && [[ -d /data/adb/ksu ]] && ksu="ksu"
else
    if [[ -d /data/adb/ksu ]]; then
        Manager_version=KernelSU
        ksu="ksu"
    fi
fi
Socname="$(getprop ro.soc.model)"
if [[ $Socname != "" ]]; then
    if [[ -f $tools_path/soc.json ]]; then
        jq -r --arg device "$Socname" '.[$device] | "Processor:\(.VENDOR) \(.NAME)"' "$tools_path/soc.json" &>/dev/null
        if [[ $? = 0 ]]; then
          DEVICE_NAME="$(jq -r --arg device "$Socname" '.[$device] | "Processor:\(.VENDOR) \(.NAME)"' "$tools_path/soc.json" 2>/dev/null)"
          jq -r --arg device "$Socname" '.[$device] | "RAM:\(.MEMORY) \(.CHANNELS)"' "$tools_path/soc.json" &>/dev/null
          if [[ $? = 0 ]]; then RAMINFO="$(jq -r --arg device "$Socname" '.[$device] | "RAM:\(.MEMORY) \(.CHANNELS)"' "$tools_path/soc.json" 2>/dev/null)"
else
RAMINFO="RAM:null"
fi
else
DEVICE_NAME="Processor:null"
RAMINFO="RAM:null"
fi
else
DEVICE_NAME="Processor:null"
RAMINFO="RAM:null"
fi
else
DEVICE_NAME="Processor:null"
RAMINFO="RAM:null"
fi
echoRgb "---------------------SpeedBackup---------------------"
echoRgb "Script path:$MODDIR\n - Booted:$(Show_boottime)\n - Run time:$(date +"%Y-%m-%d %H:%M:%S")\n -busybox path:$(which busybox)\n -busybox version:$(busybox | head -1 | awk '{print $2}')\n -script version:$backup_version\n -Manager:$Manager_version\n -brand:$(getprop ro.product.brand 2>/dev/null)\n -model:$Device_name($(getprop ro.product.device 2>/dev/null))\n -flash memory:$UFS_MODEL($ROM_TYPE)\n -$DEVICE_NAME\n -$RAMINFO\n -Android version:$(getprop ro.build.version.release 2>/dev/null) SDK:$(getprop ro.build.version.sdk 2>/dev/null)\n -kernel:$(uname -r)\n -Selinux status: $([[ $(getenforce) = Permissive ]] && echo "Permissive" || echo "Strict")\n -By@YAWAsau\n -Support: https://jq.qq.com/?_wv=1027&k=f5clPNC3"
case $MODDIR in
*Backup_*)
if [[ -f $MODDIR/app_details.json ]]; then
if [[ -d ${MODDIR%/*/*}/tools ]]; then
path_hierarchy="${MODDIR%/*/*}"
else
path_hierarchy="${MODDIR%/*}"
fi
else
if [[ -d ${MODDIR%/*}/tools ]]; then
path_hierarchy="${MODDIR%/*}"
else
[[ -d $MODDIR/tools ]] && path_hierarchy="$MODDIR"
fi
fi ;;
*) [[ -d $MODDIR/tools ]] && path_hierarchy="$MODDIR" ;;
esac
[[ $LANG = "" ]] && echoRgb "System language acquisition failed without parameter\n -If you need to change the script language, please change it in $conf_path\n -Shell_LANG=fill in the corresponding number" "0"
case $LANG in
*TW* | *tw* | *HK*)
echoRgb "System language environment: Traditional Chinese"
Script_target_language="zh-TW" ;;
*CN* | *cn*)
echoRgb "System language environment: Simplified Chinese"
Script_target_language="zh-CN" ;;
esac
Enter_options() {
echoRgb "$1" "2"
unset option parameter
while true ;do
if [[ $option != "" ]]; then
case $option in
0|1)
parameter="$option"
[[ $option = 1 ]] && echoRgb "$2" "2" || echoRgb "$3" "2"
break ;;
*)
echoRgb "$option parameter error can only be 0 or 1" "0"
read option ;;
esac
else
read option
fi
done
}
add_entry() {
app_name="$1"
package_name="$2"
# Check if the same application name already exists
if [[ $(echo "$3" | awk '{print $1}' | grep -w "^$app_name$") = $app_name ]]; then
if [[ $(echo "$3" | awk '{print $2}' | grep -w "^$package_name$") != $package_name ]]; then
# If the application name exists but the package name is different, you need to add a numeric suffix
count=1
new_app_name="${app_name}_${count}"
while echo "$3" | grep -q "$new_app_name"; do
                count=$((count + 1))
                new_app_name="${app_name}_${count}"
            done
            app_name="$new_app_name"
        fi
    fi
    REPLY="$app_name $package_name"
}
case $operate in
backup|Restore|Restore2|Getlist|backup_media)
    if [[ $backup_mode = "" ]]; then
        if [[ $user = "" ]]; then
    	    user_id="$(ls /data/user | tr ' ' '\n')"
    	    if [[ $user_id != "" && $(ls /data/user | tr ' ' '\n' | wc -l) -gt 1 ]]; then
    		    echo "$user_id" | while read ; do
    			    [[ $REPLY = 0 ]] && echoRgb "Main user:$REPLY" "2" || echoRgb "Duplicate user: $REPLY" "2"
done
echoRgb "Multiple users exist on the device, select the target user"
if [[ $(echo "$user_id" | wc -l) = 2 ]]; then
user1="$(echo "$user_id" | sed -n '1p')"
user2="$(echo "$user_id" | sed -n '2p')"
case $Lo in
0|1)
echoRgb "Select user on volume: $user1, select user on volume: $user2" "2"
Select_user="true"
get_version "$user1" "$user2" && user="$branch"
unset Select_user ;;
2)
Enter_options "Enter 1 to select user: $user1 0 user: $user2" "$user1" "$user2"
case $parameter in
0) user="$user2" ;;
1) user="$user1" ;;
esac ;;
esac
else
while true ;do
if [[ $option != "" ]]; then
user="$option"
break
else
echoRgb "Please enter the target partition to be operated" "1"
read option
fi
done
fi
else
user="0"
fi
else
user_id="$(ls /data/user | tr ' ' '\n')"
if [[ $user_id != "" && $(ls /data/user | tr ' ' '\n' | wc -l) -gt 1 ]]; then
echo "$user_id" | while read ; do
[[ $REPLY = 0 ]] && echoRgb "Primary user: $REPLY" "2" || echoRgb "Clone user:$REPLY" "2"
    		    done
    		else
    		    echoRgb "Main user:$user_id" "2"
    	    fi
    	fi
    else
        case $Compression_method in
		tar | TAR | Tar) user="$(echo "${0%}" | sed 's/.*\/Backup_tar_\([0-9]*\).*/\1/')" ;;
		zstd | Zstd | ZSTD) user="$(echo "${0%}" | sed 's/.*\/Backup_zstd_\([0-9]*\).*/\1/')" ;;
		esac
    fi
    [[ $user != 0 ]] && am start-user "$user"
	path="/data/media/$user/Android"
    path2="/data/user/$user" path3="/data/user_de/$user"
[[ ! -d $path2 ]] && echoRgb "$user partition does not exist, please fill in the user id prompted above according to the requirements\n -$conf_path configuration item user=, only one can be filled in at a time" "0" && exit 2
echoRgb "Current operation is user $user"
export USER_ID="$user" ;;
esac
unset LD_LIBRARY_PATH
#Because of the problem of receiving USER_ID environment variable, the function is placed here
alias appinfo="app_process /system/bin com.xayah.dex.HiddenApiUtil getInstalledPackagesAsUser $USER_ID $@"
alias appinfo2="app_process /system/bin com.xayah.dex.HiddenApiUtil getPackageLabel $USER_ID $@"
alias appinfo3="app_process /system/bin com.xayah.dex.HiddenApiUtil getPackageArchiveInfo $@"
alias get_ssaid="app_process /system/bin com.xayah.dex.SsaidUtil get $USER_ID $@"
alias set_ssaid="app_process /system/bin com.xayah.dex.SsaidUtil set $USER_ID $@"
alias get_uid="app_process /system/bin com.xayah.dex.HiddenApiUtil getPackageUid $USER_ID $@"
alias get_Permissions="app_process /system/bin com.xayah.dex.HiddenApiUtil getRuntimePermissions $USER_ID $@"
alias Set_true_Permissions="app_process /system/bin com.xayah.dex.HiddenApiUtil grantRuntimePermission $USER_ID $@"
alias Set_false_Permissions="app_process /system/bin com.xayah.dex.HiddenApiUtil revokeRuntimePermission $USER_ID $@"
alias Set_Ops="app_process /system/bin com.xayah.dex.HiddenApiUtil setOpsMode $USER_ID $@"
alias setDisplay="app_process /system/bin com.xayah.dex.HiddenApiUtil setDisplayPowerMode $@"
find_tools_path="$(find "$path_hierarchy"/* -maxdepth 1 -name "tools" -type d ! -path "$path_hierarchy/tools")"
Rename_script () {
    HT="${HT:=0}"
	find "$path_hierarchy" -maxdepth 3 -name "*.sh" -type f -not -name "tools.sh" | sort | while read; do
        Script_type="$(grep -o 'operate="[^"]*"' "$REPLY" 2>/dev/null | awk -F'=' '{print $2}' | tr -d '"' | head -1)"
        MODDIR_NAME="${REPLY%/*}"
        FILE_NAME="${REPLY##*/}"
        case $Script_type in
        backup|Getlist|backup_media|Restore|dumpname|check_file|convert|Restore3|Restore2)
            if [[ -f ${REPLY%/*}/app_details.json || -f ${REPLY%/*}/app_details ]]; then
	            if [[ $FILE_NAME = backup.sh ]]; then
                    touch_shell "$Script_type" "$REPLY" "backup_mode" "backup_mode=\"1\""
else
touch_shell "$Script_type" "$REPLY"
fi
else
if [[ -d ${REPLY%/*}/tools ]]; then
touch_shell "$Script_type" "$REPLY"
if [[ $Script_target_language != $shell_language ]]; then
[[ $HT = 0 && $K = "" ]] && echoRgb "Script language is $shell_language....Converting to $Script_target_language, please wait for the conversion...."
ts <"$REPLY">temp && cp temp "$REPLY" && rm temp
echo_log "$(echo "$REPLY" | sed "s|^$path_hierarchy/||")Translation"
mv "$REPLY" "$MODDIR_NAME/$(ts "$FILE_NAME")"
fi
fi
let HT++
fi ;;
kill_script)
if [[ $Script_target_language != $shell_language ]]; then
[[ $HT = 0 && $K = "" ]] && echoRgb "Script language is $shell_language....Converting to $Script_target_language, please wait for the conversion...."
ts <"$REPLY">temp && cp temp "$REPLY" && rm temp
echo_log "$(echo "$REPLY" | sed "s|^$path_hierarchy/||")Translation"
mv "$REPLY" "$MODDIR_NAME/$(ts "$FILE_NAME")"
let HT++
fi ;;
esac
done
unset HT
}
touch_shell () {
    unset conf_path MODDIR_Path Update_backup
    MODDIR_Path='${0%/*}'
    MODDIR_NAME2="${2%/*}"
	MODDIR_NAME2="${MODDIR_NAME2##*/}"
    conf_path='${0%/*}/backup_settings.conf'
    case $1 in
    Restore2)
        MODDIR_Path='${0%/*/*}'
        conf_path='${0%/*/*}/restore_settings.conf' ;;
    backup)
        if [[ $3 = backup_mode ]]; then
            MODDIR_Path='${0%/*/*/*}'
            conf_path='${0%/*/*/*}/backup_settings.conf'
        else
            [[ $(basename "$2" | awk '{print length($0)}') -gt 15 ]] && Update_backup=1
        fi ;;
    Restore|convert|dumpname|Restore3|check_file) conf_path='${0%/*}/restore_settings.conf' ;;
    esac
    if [[ $4 != "" ]]; then
        [[ $Output_path = "" ]] && echo "if [ -f \"$MODDIR_Path/tools/tools.sh\" ]; then
    MODDIR=\"$MODDIR_Path\"
    operate=\"$1\"
    $4
    conf_path=\"$conf_path\"
    case \$(grep -o 'background_execution=.*' \"\$conf_path\" | awk -F '=' '{print \$2}') in
    0)
        . \"$MODDIR_Path/tools/tools.sh\" | tee \"\${0%/*}/log.txt\" ;;
1)
{
. \"$MODDIR_Path/tools/tools.sh\" | tee \"\${0%/*}/log.txt\"
} & ;;
esac
else
echo \"$MODDIR_Path/tools/tools.sh missing\"
fi" >"$2"
else
echo "[ \"\$(echo \"\${0%/*}\" | grep -o 'bin.mt.plus/temp')\" != \"\" ] && echo \"Didn't your mom tell you to unzip the script? Idiot play\" && exit 2
if [ -f \"$MODDIR_Path/tools/tools.sh\" ]; then
    MODDIR=\"\${0%/*}\"
    operate=\"$1\"
    conf_path=\"$conf_path\"
    Update_backup=\"$Update_backup\"
    [ ! -f \"$conf_path\" ] && . \"\${0%/*}/tools/tools.sh\"
    case \$(grep -o 'background_execution=.*' \"\$conf_path\" | awk -F '=' '{print \$2}') in
    0)
        . \"$MODDIR_Path/tools/tools.sh\" | tee \"\${0%/*}/log.txt\" ;;
    1)
        {
        . \"$MODDIR_Path/tools/tools.sh\" | tee \"\${0%/*}/log.txt\"
        } & ;;
    esac
else
    echo \"$MODDIR_Path/tools/tools.sh is missing\"
fi" >"$2"
    fi
}
update_script() {
	[[ $zipFile = "" ]] && zipFile="$(find "$MODDIR" -maxdepth 1 -name "*.zip" -type f 2>/dev/null)"
	if [[ $zipFile != "" ]]; then
		case $(echo "$zipFile" | wc -l) in
		1)
			if [[ $(unzip -l "$zipFile" | awk '{print $4}' | egrep -o "^backup_settings.conf$") != "" ]]; then
				unzip -o "$zipFile" -j "tools/tools.sh" -d "$MODDIR" &>/dev/null
				if [[ -f $MODDIR/tools.sh ]]; then
				    if [[ $(expr "$(echo "$backup_version" | tr -d "a-zA-Z")" \> "$(awk '/backup_version/{print $1}' "$MODDIR/tools.sh" | cut -f2 -d '=' | head -1 | sed 's/\"//g' | tr -d "a-zA-Z")") -eq 0 ]]; then
					    shell_language="$(awk -F= '/^shell_language=/ {gsub(/"/, "", $2); print $2}' "$MODDIR/tools.sh")"
					    case $MODDIR in
					    *Backup_*)
						    if [[ -f $MODDIR/app_details.json ]]; then
                                echoRgb "Please update the script in ${MODDIR%/*}" "0"
                                rm -rf "$MODDIR/tools.sh"
                                exit 2
                            fi ;;
					    esac
					    echoRgb "Update from $zipFile"
					    if [[ -d $path_hierarchy/tools ]]; then
					        mv "$path_hierarchy/tools" "$TMPDIR"
unzip -o "$zipFile" tools/* -d "$path_hierarchy" | sed 's/inflating/release/g ; s/creating/create/g ; s/Archive/decompression/g'
echo_log "decompress ${zipFile##*/}"
if [[ $result = 0 ]]; then
if [[ $shell_language != $Script_target_language ]]; then
echoRgb "The script language is $shell_language....Converting to $Script_target_language, please wait for the conversion...."
ts <"$path_hierarchy/tools/Device_List">temp && cp temp "$path_hierarchy/tools/Device_List" && rm temp
                                    echo_log "$path_hierarchy/tools/Device_List translation"
					                ts <"$path_hierarchy/tools/tools.sh">temp && cp temp "$path_hierarchy/tools/tools.sh" && rm temp && sed "s/shell_language=\"$shell_language\"/shell_language=\"$Script_target_language\"/g" "$path_hierarchy/tools/tools.sh" > temp && cp temp "$path_hierarchy/tools/tools.sh" && rm temp
                                    echo_log "$path_hierarchy/tools/tools.sh translation"
                                    HT=1
                                fi
                                update_backup_settings_conf>"$path_hierarchy/backup_settings.conf"
                                ts <"$path_hierarchy/backup_settings.conf">temp && cp temp "$path_hierarchy/backup_settings.conf" && rm temp
                                echo_log "$path_hierarchy/backup_settings.conf translation"
                                if [[ -d $find_tools_path && $find_tools_path != $path_hierarchy/tools ]]; then
                                    rm -rf "$find_tools_path"
                                    cp -r "$path_hierarchy/tools" "${find_tools_path%/*}"
                                    update_Restore_settings_conf>"${find_tools_path%/*}/restore_settings.conf"
                                    ts <"${find_tools_path%/*}/restore_settings.conf">temp && cp temp "${find_tools_path%/*}/restore_settings.conf" && rm temp
                                    echo_log "${find_tools_path%/*}/restore_settings.conf translation"
							    fi
							    Rename_script
							    if [[ $Output_path != "" ]]; then
		                            [[ ${Output_path: -1} = / ]] && Output_path="${Output_path%?}"
		                            if [[ ${Output_path:0:1} != / ]]; then
		                                update_path="$MODDIR/$Output_path/Backup_${Compression_method}_$user"
		                            else
		                                update_path="$Output_path/Backup_${Compression_method}_$user"
		                            fi
		                            rm -rf "$update_path/tools"
		                            cp -r "$path_hierarchy/tools" "$update_path" echoRgb "$update_path/tools has been updated"
fi
else
mv "$TMPDIR/tools" "$MODDIR"
fi
rm -rf "$TMPDIR"/* "$zipFile" "$MODDIR/tools.sh"
echoRgb "Update completed. Please re-execute the script" "2"
exit
fi
else
echoRgb "${zipFile##*/} version is lower than the current version, automatically deleted" "0"
rm -rf "$zipFile" "$path_hierarchy/tools.sh"
fi
else
rm -rf "$zipFile"
unset zipFile
fi
fi ;;
*)
echoRgb "Error. Please delete the redundant zip in the current directory\n -Keep a latest data backup.zip\n -The following is the current directory zip\n$zipFile" "0"
			exit 1 ;;
		esac
	fi
	unset NAME
}
update_script
zipFile="$(ls -t /storage/emulated/0/Download/*.zip 2>/dev/null | head -1)"
if [[ $(unzip -l "$zipFile" 2>/dev/null | awk '{print $4}' | egrep -wo "^backup_settings.conf$") != "" ]]; then
    update_script
else
    zipFile="$(ls -t /storage/emulated/0/Android/data/com.tencent.mobileqq/Tencent/QQfile_recv/*.zip 2>/dev/null | head -1)"
    [[ $(unzip -l "$zipFile" 2>/dev/null | awk '{print $4}' | egrep -wo "^backup_settings.conf$") != "" ]] && update_script
fi
if [[ $(getprop ro.build.version.sdk) -lt 30 ]]; then
	alias INSTALL="pm install --user $user -r -t &>/dev/null"
	alias create="pm install-create --user $user -t 2>/dev/null"
else
    if [[ $(getprop ro.build.version.sdk) -gt 33 ]]; then
	    alias INSTALL="pm install -r --bypass-low-target-sdk-block -i com.android.vending --user $user -t &>/dev/null"
        alias create="pm install-create -i com.android.vending --bypass-low-target-sdk-block --user $user -t 2>/dev/null"
    else
        alias INSTALL="pm install -r -i com.android.vending --user $user -t &>/dev/null"
        alias create="pm install-create -i com.android.vending --user $user -t 2>/dev/null"
    fi
fi
cdn=2
#settings get system system_locales
Language="https://api.github.com/repos/YAWAsau/backup_script/releases/latest"
if [[ $path_hierarchy != "" && $Script_target_language != "" ]]; then
	K=1
	J="$(find "$path_hierarchy" -maxdepth 3 -name "tools.sh" -type f | wc -l)"
	find "$path_hierarchy" -maxdepth 3 -name "tools.sh" -type f | while read ; do
	    unset shell_language
	    shell_language="$(awk -F= '/^shell_language=/ {gsub(/"/, "", $2); print $2}' "$REPLY")"
case $shell_language in
zh-CN|zh-TW)
if [[ $Script_target_language != $shell_language ]]; then
[[ $K = 1 ]] && echoRgb "Script language is $shell_language....Converting to $Script_target_language, please wait for the conversion...."
ts <"$REPLY">temp && cp temp "$REPLY" && rm temp
if [[ $? = 0 ]]; then
touch "$TMPDIR/0"
echo_log "$(echo "$REPLY" | sed "s|^$path_hierarchy/||")Translation"
MODDIR="${0%/*}"
if [[ -f ${REPLY%/*/*}/backup_settings.conf ]]; then
                        update_backup_settings_conf>"${REPLY%/*/*}/backup_settings.conf"
                        ts <"${REPLY%/*/*}/backup_settings.conf">temp && cp temp "${REPLY%/*/*}/backup_settings.conf" && rm temp
                        echo_log "${REPLY%/*/*}/backup_settings.conf translation"
                    fi
                    if [[ -f ${REPLY%/*/*}/restore_settings.conf ]]; then
                        update_Restore_settings_conf>"${REPLY%/*/*}/restore_settings.conf"
                        ts <"${REPLY%/*/*}/restore_settings.conf">temp && cp temp "${REPLY%/*/*}/restore_settings.conf" && rm temp
                        echo_log "${REPLY%/*/*}/restore_settings.conf translation"
                    fi
	                sed "s/shell_language=\"$shell_language\"/shell_language=\"$Script_target_language\"/g" "$REPLY" > temp && cp temp "$REPLY" && rm temp
	                [[ $shell_language != $(awk -F= '/^shell_language=/ {gsub(/"/, "", $2); print $2}' "$REPLY") ]] && echoRgb "$(echo "$REPLY" | sed "s|^$path_hierarchy/||")Variable modification successful" || echoRgb "$(echo "$REPLY" | sed "s|^$path_hierarchy/||") variable modification failed" "0"
ts <"${REPLY%/*}/Device_List">temp && cp temp "${REPLY%/*}/Device_List" && rm temp
echo_log "${REPLY%/*}/Device_List translation"
[[ $K = 1 ]] && Rename_script
else
echoRgb "$REPLY ts process error" "0"
fi
let K++
fi ;;
esac
done
[[ -e $TMPDIR/0 ]] && rm -rf "$TMPDIR/0" && echoRgb "Script conversion completed, exit the script and re-execute to use" && exit 2
fi
#Verify whether the options are correct
case $Lo in
0)
[[ $update != "" ]] && isBoolean "$update" "update" && update="$nsx" || {
echoRgb "Automatically update script?\n - Update volume up, not down"
get_version "update" "Not update" && update="$branch"
} ;;
1)
[[ $update = "" ]] && {
echoRgb "Automatically update script?\n - Update volume up, not down"
get_version "update" "Not update" && update="$branch"
} || isBoolean "$update" "update" && update="$nsx" ;;
2)
[[ $update = "" ]] && {
Enter_options "Enter 1 to automatically update the script, enter 0 not to automatically update the script" "Update" "Not update" && isBoolean "$parameter" "update" && update="$nsx"
} || {
isBoolean "$update" "update" && update="$nsx"
} ;;
*) echoRgb "$conf_path Lo=$Lo is incorrectly filled in, the correct value is 0 1 2" "0" && exit 2 ;;
esac
[[ $update = true ]] && json="$(down "$Language" 2>/dev/null)" || echoRgb "Automatic update is closed" "0"
if [[ $json != "" ]]; then
tag="$(jq -r '.tag_name'<<< "$json")"
if [[ $tag != "" && $backup_version != $tag ]]; then
if [[ $(expr "$(echo "$backup_version" | tr -d "a-zA-Z")" \> "$(echo "$tag" | tr -d "a-zA-Z")") -eq 0 ]]; then
			download="$(jq -r '.assets[].browser_download_url'<<< "$json")"
			case $cdn in
			1) zip_url="http://huge.cf/download/?huge-url=$download" ;;
			2) zip_url="https://github.moeyy.xyz/$download" ;;
			3) zip_url="https://gh.api.99988866.xyz/$download" ;;
			4) zip_url="https://github.lx164.workers.dev/$download" ;;
			5) zip_url="https://shrill-pond-3e81.hunsh.workers.dev/$download" ;; esac
if [[ $(expr "$(echo "$backup_version" | tr -d "a-zA-Z")" \> "$(echo "$download" | tr -d "a-zA-Z")") -eq 0 ]]; then
echoRgb "New version found: $tag"
if [[ $update = true ]]; then
echoRgb "$(ts "Update log:\n$(down "$Language" | jq -r '.body' 2>/dev/null)")"
case $Lo in
0|1) 
echoRgb "Do you want to update the script? \n -update on volume, not update on volume" "2"
get_version "update" "not update" && choose="$branch" ;;
2)
Enter_options "Enter 1 to automatically update the script, enter 0 not to automatically update the script" "update" "not update" && isBoolean "$parameter" "update" && update="$nsx" ;;
esac
if [[ $choose = true ]]; then
echoRgb "Downloading... Wait patiently. If the download fails, please hang up the plane"
starttime1="$(date -u "+%s")"
down "$zip_url" >"$MODDIR/update.zip" &
wait
endtime 1
[[ ! -f $MODDIR/update.zip ]] && echoRgb "Download failed" && exit 2
zipFile="$MODDIR/update.zip"
fi
else
echoRgb "update option in $conf_path is 0, ignore update, only prompt update" "0"
fi
fi
fi
fi
else
[[ $update = true ]] && echoRgb "Update failed" "0"
fi
update_script
backup_path() {
if [[ $Output_path != "" ]]; then
[[ ${Output_path: -1} = / ]] && Output_path="${Output_path%?}"
if [[ ${Output_path:0:1} != / ]]; then
Directory_type="Relative path"
Backup="$MODDIR/$Output_path/Backup_${Compression_method}_$user"
else
Directory_type="Absolute path"
Backup="$Output_path/Backup_${Compression_method}_$user"
fi
outshow="Use custom directory ($Directory_type)"
else
Backup="$MODDIR/Backup_${Compression_method}_$user"
if [[ $backup_mode = "" ]]; then
outshow="Use current path as backup directory"
else
[[ -d $Backup ]] && outshow="Use parent path as backup directory" || echoRgb "$Backup directory does not exist" "0"
fi
fi
PU=$(mount | awk '$3 ~ "/mnt/media_rw/[^/]+$" {print $3, $5}' | egrep -v "$mount_point")
OTGPATH="$(echo "$PU" | awk '{print $1}')"
OTGFormat="$(echo "$PU" | awk '{print $2}')"
if [[ -d $OTGPATH ]]; then
if [[ $(echo "$MODDIR" | egrep -o "^${OTGPATH}") != "" ]]; then
hx="true"
Backup="$MODDIR/Backup_${Compression_method}_$user"
else
case $Lo in
0|1)
echoRgb "Detected whether the USB is in the USB backup\n - yes on the volume, no on the volume" "2"
get_version "Selected USB backup" "Selected local backup" ;;
2)
Enter_options "USB drive detected, enter 1 to use USB backup 0 local backup" "USB backup selected" "local backup" && isBoolean "$parameter" "branch" && branch="$nsx" ;;
esac
[[ $branch = true ]] && hx="$branch"
[[ $hx = true ]] && Backup="$OTGPATH/Backup_${Compression_method}_$user"
fi
if [[ $hx = true ]]; then
if [[ $OTGFormat = vfat ]]; then
echoRgb "USB file system $OTGFormat does not support single file larger than 4GB\n - Please format to exfat" "0"
exit 
fi
outshow="Backup to USB" && hx=usb
fi
fi
[[ ! -d $Backup ]] && mkdir -p "$Backup"
#Partition details
if [[ $(echo "$Backup" | egrep -o "^/storage/emulated") != "" ]]; then
Backup_path="/data"
else
Backup_path="${Backup%/*}"
fi
echoRgb "$hx The partition statistics used by the backup folder are as follows↓\n -$(df -h "${Backup%/*}" | sed -n 's|%/.*|%|p' | awk '{print $(NF-3),$(NF-2),$(NF-1),$(NF)}' | awk 'END{print "Total:"$1" Used:"$2" Remaining:"$3" Usage rate:"$4}') File system:$(df -T "$Backup_path" | sed -n 's|%/.*|%|p' | awk '{print $(NF-4)}')\n - backup directory output location↓\n -$Backup"
echoRgb "$outshow" "2"
}
Calculate_size() {
#Calculate the backup size and difference
filesizee="$(find "$1" -type f -printf "%s\n" | awk '{s+=$1} END {print s}')"
if [[ $(echo "$filesizee > $filesize" | bc) -eq 1 ]]; then
NJL="This backup increases $(size "$(echo "scale=2; $filesizee - $filesize" | bc)")"
elif [[ $(echo "$filesizee < $filesize" | bc) -eq 1 ]]; then
NJL="This backup decreases $(size "$(echo "scale=2; $filesize - $filesizee" | bc)")"
else
NJL="File size has not changed"
fi
echoRgb "Backup folder path↓↓↓\n -$1"
echoRgb "Backup folder total size$(size "$filesizee")"
echoRgb "$NJL"
}
size() {
local b_size get_size
varr="$(echo "$1" | bc 2>/dev/null)"
if [[ $varr != $1 ]]; then
b_size="$(ls -l "$1" 2>/dev/null | awk '{print $5}')"
else
b_size="$1"
fi
if [[ $b_size -eq 0 ]]; then
get_size="0 bytes"
elif [[ $(echo "$b_size < 1024" | bc) -eq 1 ]]; then
        get_size="${b_size} bytes"
    elif [[ $(echo "$b_size < 1048576" | bc) -eq 1 ]]; then
        get_size="$(echo "scale=2; $b_size / 1024" | bc) KB"
    elif [[ $(echo "$b_size < 1073741824" | bc) -eq 1 ]]; then
        get_size="$(echo "scale=2; $b_size / 1048576" | bc) MB"
    else
        get_size="$(echo "scale=2; $b_size / 1073741824" | bc) GB"
    fi
    echo "$get_size"
}
#Partition occupancy information
partition_info() {
unset Skip
Occupation_status="$(df -B1 "${1%/*}" | sed -n 's|%/.*|%|p' | awk '{print $(NF-1)}')"
Filesize2="$(size "$Filesize")"
echo " -$2 size:$Filesize2 remaining size:$(size "$Occupation_status")"
[[ $Filesize != "" ]] && [[ $(echo "$Filesize > $Occupation_status" | bc) -eq 1 ]] && echoRgb "$2 backup size will exceed rom available size" "0" && Skip=1
Occupation_status="$(df -h "${Backup%/*}" | sed -n 's|%/.*|%|p' | awk '{print $(NF-1),$(NF)}')"
}
kill_app() {
    if [[ $name2 != bin.mt.plus && $name2 != com.termux && $name2 != bin.mt.plus.canary ]]; then
        if [[ $(dumpsys activity processes | grep "packageList" | cut -d '{' -f2 | cut -d '}' -f1 | egrep -w "^$name2$" | sed -n '1p') = $name2 ]]; then
            pkill -9 -f "$name2$|$name2[:/_]"
            killall -9 "$name2" &>/dev/null
            am force-stop --user "$user" "$name2" &>/dev/null
            am kill "$name2" &>/dev/null
echoRgb "Kill $name1 process"
fi
fi
}
Backup_apk() {
#Detect apk status for backup
#Create APP backup folder
[[ ! -d $Backup_folder ]] && mkdir -p "$Backup_folder"
[[ ! -f $app_details ]] && echo "{\n}">"$app_details"
apk_version="$(jq -r '.[] | select(.apk_version != null).apk_version' "$app_details")"
apk_version2="$(pm list packages --show-versioncode --user "$user" "$name2" 2>/dev/null | cut -f3 -d ':' | head -n 1)"
if [[ $apk_version = $apk_version2 ]]; then
[[ $(sed -e '/^$/d' "$txt2" | awk '{print $2}' | grep -w "^${name2}$" | head -1) = "" ]] && echo "${Backup_folder##*/} $name2" >>"$txt2"
unset xb
let osj++
result=0
echoRgb "Apk version not updated, skip backup" "2"
else
if [[ $nobackup = false ]]; then
if [[ $apk_version != "" ]]; then
let osn++
update_apk="$(echo "$name1 \"$name2\"")"
update_apk2="$(echo "$update_apk\n$update_apk2")"
echoRgb "Version:$apk_version>$apk_version2"
else
let osk++
				add_app="$(echo "$name1 \"$name2\"")"
				add_app2="$(echo "$add_app\n$add_app2")"
				echoRgb "Version:$apk_version2"
			fi
			unset Filesize
			Filesize="$(find "$apk_path2" -type f -printf "%s\n" | awk '{s+=$1} END {print s}')"
			rm -rf "$Backup_folder/apk.tar"*
			partition_info "$Backup" "$name1 apk"
			if [[ $Skip != 1 ]]; then
    			#Backup apk
    			echoRgb "$1"
    			echo "$apk_path" | sed -e '/^$/d' | while read; do
    				echoRgb "${REPLY##*/} $(size "$REPLY")"
    			done    			(
    				cd "$apk_path2"
    				case $Compression_method in
    				tar | TAR | Tar) tar --checkpoint-action="ttyout=%T\r" -cf "$Backup_folder/apk.tar" *.apk ;;
    				zstd | Zstd | ZSTD) tar --checkpoint-action="ttyout=%T\r" -cf - *.apk | zstd --ultra -3 -T0 -q --priority=rt >"$Backup_folder/apk.tar.zst" ;;
    				esac
    			)
    			echo_log "Back up $apk_number Apk"
    			if [[ $result = 0 ]]; then
    			    Validation_file "$Backup_folder/apk.tar"*
    				if [[ $result = 0 ]]; then
    					[[ $(sed -e '/^$/d' "$txt2" 2>/dev/null | awk '{print $2}' | grep -w "^${name2}$" | head -1) = "" ]] && echo "${Backup_folder##*/} $name2" >>"$txt2"
                        [[ $apk_version != "" ]] && {
                        echoRgb "Override app_details"
                        jq --arg apk_version "$apk_version2" --arg software "$name1" '.[$software].apk_version = $apk_version' "$app_details" > temp.json && cp temp.json "$app_details" && rm -rf temp.json
                        } || {
                        echoRgb "Add app_details"
                        extra_content="{
                          \"$name1\": {
                            \"PackageName\": \"$name2\", \"apk_version\": \"$apk_version2\"
}
}"
jq --argjson new_content "$extra_content" '. += $new_content' "$app_details" > temp.json && cp temp.json "$app_details" && rm -rf temp.json
}
else
rm -rf "$Backup_folder"
fi
if [[ $name2 = com.android.chrome ]]; then
#Delete all old apks and keep a newest apk for backup
ReservedNum=1
FileNum="$(ls /data/app/*/com.google.android.trichromelibrary_*/base.apk 2>/dev/null | wc -l)"
while [[ $FileNum -gt $ReservedNum ]]; do
OldFile="$(ls -rt /data/app/*/com.google.android.trichromelibrary_*/base.apk 2>/dev/null | head -1)"
    						rm -rf "${OldFile%/*/*}" && echoRgb "Delete file:${OldFile%/*/*}"
    						let "FileNum--"
    					done
    					[[ -f $(ls /data/app/*/com.google.android.trichromelibrary_*/base.apk 2>/dev/null) && $(ls /data/app/*/com.google.android.trichromelibrary_*/base.apk 2>/dev/null | wc -l) = 1 ]] && cp -r "$(ls /data/app/*/com.google.android.trichromelibrary_*/base.apk 2>/dev/null)" "$Backup_folder/nmsl.apk"    				fi
    			else
    				rm -rf "$Backup_folder"
    			fi
    	    fi
		else
			let osj++
			rm -rf "$Backup_folder"
		fi
	fi
	[[ $name2 = bin.mt.plus && ! -f $Backup/$name1.apk ]] && cp -r "$apk_path" "$Backup/$name1.apk"
}
Backup_ssaid() {
    Ssaid="$(jq -r '.[] | select(.Ssaid != null).Ssaid' "$app_details")"
    ssaid="$(get_ssaid "$name2")"
    [[ $ssaid != null ]] && echoRgb "SSAID:$ssaid"
    if [[ $ssaid != null && $ssaid != $Ssaid ]]; then
        echoRgb "$Ssaid>$ssaid"
    	SSAID_apk="$(echo "$name1 \"$name2\"")"
        SSAID_apk2="$(echo "$SSAID_apk\n$SSAID_apk2")"
    	jq --arg entry "$name1" --arg new_value "$ssaid" '.[$entry].Ssaid |= $new_value' "$app_details" > temp.json && cp temp.json "$app_details" && rm -rf temp.json
    	echo_log "backup ssaid"
    fi
    [[ $ssaid = null ]] && ssaid=
}
Backup_Permissions() {
    get_Permissions="$(jq -r '.[] | select(.permissions != null).permissions' "$app_details")"
    Get_Permissions="$(get_Permissions "$name2" | jq -nR '[inputs | select(length>0) | split(" ") | {(.[0]): (.[1:] | join(" "))}] | add')"
    if [[ $Get_Permissions != "" ]]; then
        if [[ $get_Permissions = "" ]]; then jq --arg packageName "$name1" --argjson permissions "$Get_Permissions" '.[$packageName].permissions |= $permissions' "$app_details" > temp.json && cp temp.json "$app_details" && rm -rf temp.json
echo_log "Backup permissions"
else
[[ $get_Permissions != $Get_Permissions ]] && jq --arg packageName "$name1" --argjson permissions "$Get_Permissions" '.[$packageName] |= . + {permissions: $permissions}' "$app_details" > temp.json && cp temp.json "$app_details" && rm -rf temp.json && echo_log "Backup permissions" "Backup"
fi
fi
}
#Detect data location for backup
Backup_data() {
	data_path="$path/$1/$name2"
	MODDIR_NAME="${data_path%/*}"
	MODDIR_NAME="${MODDIR_NAME##*/}"
	[[ -f $app_details ]] && Size="$(jq -r --arg entry "$1" '.[$entry] | select(.Size != null).Size' "$app_details" 2>/dev/null)"
	case $1 in
	user) data_path="$path2/$name2" ;;
	user_de) data_path="$path3/$name2" ;;
	data|obb) ;;
	*)
		data_path="$2"
		if [[ $1 != storage-isolation && $1 != thanox && $1 != NoActive ]]; then
			Compression_method1="$Compression_method"			Compression_method=tar
		fi
		zsize=1
		zmediapath=1
		;;
	esac
	if [[ -d $data_path ]]; then
	    unset Filesize ssaid Get_Permissions result Permissions
        Filesize="$(find "$data_path" -type f -printf "%s\n" 2>/dev/null | awk '{s+=$1} END {print s}')"
        [[ $Filesize != "" ]] && {
		if [[ $Size != $Filesize ]]; then
            case $1 in
            user)
                if [[ $(su "$(get_uid "$name2" 2>/dev/null)" -c keystore_cli_v2 list | wc -l) -ge 2 ]]; then
                    echoRgb "$name1 contains keystore, recovery may crash" "0"
                    jq --arg entry "$name1" '.[$entry].keystore |= "true"' "$app_details" > temp.json && cp temp.json "$app_details" && rm -rf temp.json
                else
                    jq --arg entry "$name1" '.[$entry].keystore |= "false"' "$app_details" > temp.json && cp temp.json "$app_details" && rm -rf temp.json
                fi
    		    Backup_ssaid
    			Backup_Permissions ;;
    	    esac
		    #Stop application
			case $1 in
			user|data|obb|user_de) kill_app ;;
			esac
			rm -rf "$Backup_folder/$1.tar"*
			partition_info "$Backup" "$1"
			if [[ $Skip != 1 ]]; then
    			echoRgb "Backup $1 data"
    			# Determine whether the specified size is exceeded
                if [[ $Filesize2 != *"bytes"* ]]; then
                    if [[ $Filesize2 = *"KB"* ]]; then
                        if [[ $(echo "${Filesize2% KB}" | bc) > 1 ]]; then
                            Start_backup="true"
                        else
                            Start_backup="false"
                        fi
                    else
                        Start_backup="true"
                    fi
                else
                    Start_backup="false"
                fi
                [[ $Start_backup = true ]] && {
    			case $1 in
    			user|user_de)
    				case $Compression_method in
    				tar | Tar | TAR) tar --checkpoint-action="ttyout=%T\r" --exclude="${data_path##*/}/.ota" --exclude="${data_path##*/}/cache" --exclude="${data_path##*/}/lib" --exclude="${data_path##*/}/code_cache" --exclude="${data_path##*/}/no_backup" --warning=no-file-changed -cpf "$Backup_folder/$1.tar" -C "${data_path%/*}" "${data_path##*/}" 2>/dev/null ;;
    				zstd | Zstd | ZSTD) tar --checkpoint-action="ttyout=%T\r" --exclude="${data_path##*/}/.ota" --exclude="${data_path##*/}/cache" --exclude="${data_path##*/}/lib" --exclude="${data_path##*/}/code_cache" --exclude="${data_path##*/}/no_backup" --warning=no-file-changed -cpf - -C "${data_path%/*}" "${data_path##*/}" | zstd --ultra -3 -T0 -q --priority=rt >"$Backup_folder/$1.tar.zst" 2>/dev/null ;;
    				esac
    				;;
    			*)
        		    case $Compression_method in
        		    tar | Tar | TAR) tar --checkpoint-action="ttyout=%T\r" --exclude="Backup_"* --exclude="${data_path##*/}/cache" --exclude="${data_path##*/}/QQ" --exclude="${data_path##*/}/Telegram" --exclude="${data_path##*/}"/.* --warning=no-file-changed -cpf "$Backup_folder/$1.tar" -C "${data_path%/*}" "${data_path##*/}" ;;
        			zstd | Zstd | ZSTD) tar --checkpoint-action="ttyout=%T\r" --exclude="Backup_"* --exclude="${data_path##*/}/cache" --exclude="${data_path##*/}/QQ" --exclude="${data_path##*/}/Telegram" --exclude="${data_path##*/}"/.* --warning=no-file-changed -cpf - -C "${data_path%/*}" "${data_path##*/}" | zstd --ultra -3 -T0 -q --priority=rt >"$Backup_folder/$1.tar.zst" ;;
        			esac
    				;;
    			esac
    			echo_log "Backup $1 data"
    			} || {
    			echoRgb "$1data $Filesize2 is too small" "0" && result=1
    			}
    			if [[ $result = 0 ]]; then
    			    Validation_file "$Backup_folder/$1.tar"*
    				if [[ $result = 0 ]]; then
    				    if [[ ! $Filesize -eq 0 ]]; then
                            size2="$(stat -c %s "$Backup_folder/$1.tar"*)"
                            rate="$(echo "scale=2; (1 - ($size2 / $Filesize)) * 100" | bc)"
                            echoRgb "Compression rate${rate}%size$(size "$size2")"
                        fi
    				    [[ ${Backup_folder##*/} = Media ]] && [[ $(sed -e '/^$/d' "$mediatxt" | grep -w "${REPLY##*/}.tar$" | head -1) = "" ]] && echo "$FILE_NAME" >> "$mediatxt"
    					if [[ $zsize != "" ]]; then
    					    extra_content="{
                              \"$1\": {
                                \"path\": \"$2\",
                                \"Size\": \"$Filesize\"
                              },
                              \"Backup time\": {
                                \"date\": \"$(date "+%Y.%m.%d %H:%M:%S")\"
                              }
                            }"
                            jq --argjson new_content "$extra_content" '. += $new_content' "$app_details" > temp.json && cp temp.json "$app_details" && rm -rf temp.json
    					else
    					    extra_content="{
                              \"$1\": {
                                \"Size\": \"$Filesize\"
                              },
                              \"Backup time\": { \"date\": \"$(date "+%Y.%m.%d %H:%M:%S")\"
}
}"
jq --argjson new_content "$extra_content" '. += $new_content' "$app_details" > temp.json && cp temp.json "$app_details" && rm -rf temp.json
fi
else
rm -rf "$Backup_folder/$1".tar.*
fi
fi
[[ $Compression_method1 != "" ]] && Compression_method="$Compression_method1"
unset Compression_method1
fi
else
[[ $Size != "" ]] && echoRgb "$1 data has not changed. Skip backup" "2"
fi
}
else
[[ -f $data_path ]] && echoRgb "$1 is a file and does not support backup" "0"
	fi
}
Release_data() {
	tar_path="$1"
	X="$path2/$name2"
	MODDIR_NAME="${tar_path%/*}"
	MODDIR_NAME="${MODDIR_NAME##*/}"
	FILE_NAME="${tar_path##*/}"
	FILE_NAME2="${FILE_NAME%%.*}"
	case ${FILE_NAME##*.} in
	zst|tar)
		unset FILE_PATH Size Selinux_state
		[[ -f $app_details ]] && Size="$(jq -r --arg entry "$FILE_NAME2" '.[$entry] | select(.Size != null).Size' "$app_details" 2>/dev/null)"
		case $FILE_NAME2 in
		user)
		    if [[ -d $X ]]; then
[[ $(jq -r '.[] | select(.Ssaid != null).keystore' "$app_details") = true ]] && echoRgb "$name1 exists in keystore. Recovery may crash" "0"
FILE_PATH="$path2"
Selinux_state="$(LS "$X" | awk 'NF>1{print $1}' | sed -e "s/system_data_file/app_data_file/g" 2>/dev/null)"
else
echoRgb "$X does not exist. Unable to restore $FILE_NAME2 data" "0"
fi ;;
user_de)
X="$path3/$name2"
if [[ -d $X ]]; then
FILE_PATH="$path3"
Selinux_state="$(LS "$X" | awk 'NF>1{print $1}' | sed -e "s/system_data_file/app_data_file/g" 2>/dev/null)"
		    else
		        echoRgb "$X does not exist. Unable to restore $FILE_NAME2 data" "0"
		    fi ;;
		data) FILE_PATH="$path/data" Selinux_state="$(LS "$FILE_PATH" | awk 'NF>1{print $1}' | sed -e "s/system_data_file/app_data_file/g" 2>/dev/null)" ;;
		obb) FILE_PATH="$path/obb" Selinux_state="$(LS "$FILE_PATH" | awk 'NF>1{print $1}' | sed -e "s/system_data_file/app_data_file/g" 2>/dev/null)";;
		thanox) FILE_PATH="/data/system" && find "/data/system" -name "thanos"* -maxdepth 1 -type d -exec rm -rf {} \; 2>/dev/null ;;
		NoActive) FILE_PATH="/data/system" && find "/data/system" -name "NoActive_"* -maxdepth 1 -type d -exec rm -rf {} \; 2>/dev/null ;;
		storage-isolation) FILE_PATH="/data/adb" ;;
		*)
			if [[ $A != "" ]]; then
				if [[ ${MODDIR_NAME##*/} = Media ]]; then
				    FILE_PATH="$(jq -r --arg entry "${FILE_NAME2}" 'select(.[$entry].path != null).[$entry].path' "$app_details")"
					if [[ $FILE_PATH = "" ]]; then
echoRgb "Path acquisition failed" "0"
else
echoRgb "Decompression path↓\n -$FILE_PATH" "2"
FILE_PATH="${FILE_PATH%/*}"
[[ ! -d $FILE_PATH ]] && mkdir -p "$FILE_PATH"
fi
fi
else
echoRgb "$tar_path name seems to be wrong" "0"
fi ;;
esac
echoRgb "Restore $FILE_NAME2 data Release $(size "$Size")" "3"
if [[ $FILE_PATH != "" ]]; then
[[ ${MODDIR_NAME##*/} != Media ]] && rm -rf "$FILE_PATH/$name2"
case ${FILE_NAME##*.} in
			zst) tar --checkpoint-action="ttyout=%T\r" -I zstd -xmpf "$tar_path" -C "$FILE_PATH" ;;
			tar) [[ ${MODDIR_NAME##*/} = Media ]] && tar --checkpoint-action="ttyout=%T\r" -axf "$tar_path" -C "$FILE_PATH" || tar --checkpoint-action="ttyout=%T\r" -amxf "$tar_path" -C "$FILE_PATH" ;;
			esac
		else
			Set_back_1
		fi
		echo_log "Unzip ${FILE_NAME##*.}"
		if [[ $result = 0 ]]; then
			case $FILE_NAME2 in
			user|data|obb|user_de)
			    G="$(get_uid "$name2" 2>/dev/null)"
			    if [[ $G != "" ]]; then
				    G="$(dumpsys package "$name2" 2>/dev/null | awk -F'uid=' '{print $2}' | egrep -o '[0-9]+' | head -n 1)"
				    [[ $(echo "$G" | egrep -o '[0-9]+') = "" ]] && G="$(pm list packages -U --user "$user" | egrep -w "$name2" | awk -F'uid:' '{print $2}' | awk '{print $1}' | head -n 1)"
				fi
                G="$(echo "$G" | egrep -o '[0-9]+')"
				if [[ $G != "" ]]; then
					if [[ -d $X ]]; then
					    case ${#G} in
					    5)
					        if [[ $user = 0 ]]; then
					            uid="$G:$G"
					        else
					            uid="$user$G:$user$G"
					        fi ;;
					    6|7|8|9|10)
					        uid="$G:$G" ;;
					    esac
                        case $FILE_NAME2 in
                        user|user_de)
                            case $FILE_NAME2 in
                            user) [[ $X = $path2/$name2 ]] && Validation_settings="true" || Validation_settings="false" ;;
                            user_de) [[ $X = $path3/$name2 ]] && Validation_settings="true" || Validation_settings="false" ;;
                            esac
                            if [[ $Validation_settings = true ]]; then
						        chown -hR "$uid" "$X/"
						        echo_log "Set user group $uid"
						        chcon -hR "$Selinux_state" "$X/" 2>/dev/null
echo_log "selinux context setting"
else
echoRgb "Path: $X error"
fi ;;
data|obb)
chown -hR "$uid" "$FILE_PATH/$name2/"
chcon -hR "$Selinux_state" "$FILE_PATH/$name2/" 2>/dev/null ;;
esac
else
echoRgb "$FILE_NAME2 path $X does not exist" "0"
fi
else
echoRgb "uid acquisition failed" "0"
fi
;;
thanox)
restorecon -RF "$(find "/data/system" -name "thanos"* -maxdepth 1 -type d 2>/dev/null)/" 2>/dev/null
echo_log "selinux context settings" && echoRgb "Warning thanox configuration must be restarted after recovery\n - otherwise it will not take effect" "0"
;;
NoActive)
restorecon -RF "$(find "/data/system" -name "NoActive_"* -maxdepth 1 -type d 2>/dev/null)/" 2>/dev/null
echo_log "selinux context settings"
;;
storage-isolation)
restorecon -RF "/data/adb/storage-isolation/" 2>/dev/null
echo_log "selinux context settings"
;;
esac
fi
;;
*)
echoRgb "$FILE_NAME compressed package does not support decompression" "0"
Set_back_1
;;
esac
rm -rf "$TMPDIR"/*
}
installapk() {
apkfile="$(find "$Backup_folder" -maxdepth 1 -name "apk.*" -type f 2>/dev/null)"
if [[ $apkfile != "" ]]; then
rm -rf "$TMPDIR"/*
case ${apkfile##*.} in
zst) tar --checkpoint-action="ttyout=%T\r" -I zstd -xmpf "$apkfile" -C "$TMPDIR" ;;
tar) tar --checkpoint-action="ttyout=%T\r" -xmpf "$apkfile" -C "$TMPDIR" ;;
*)
echoRgb "${apkfile##*/} compressed package does not support decompression" "0"
Set_back_1
;;
esac
echo_log "${apkfile##*/} decompress" && [[ -f $Backup_folder/nmsl.apk ]] && cp -r "$Backup_folder/nmsl.apk" "$TMPDIR"
else
echoRgb "Your Apk compressed package has run away from home. It may be lost during the move process after backup\n -Solution: Manually install Apk and then execute the recovery script" "0"
fi
if [[ $result = 0 ]]; then
case $(find "$TMPDIR" -maxdepth 1 -name "*.apk" -type f 2>/dev/null | wc -l) in
1)
echoRgb "Restore normal apk" "2"
INSTALL "$TMPDIR"/*.apk
echo_log "Apk installation"
;;
0)
echoRgb "No apk in $TMPDIR" "0"
;;
*)
echoRgb "Restore split apk" "2"
b="$(create 2>/dev/null | egrep -o '[0-9]+')"
if [[ -f $TMPDIR/nmsl.apk ]]; then
INSTALL "$TMPDIR/nmsl.apk"
echo_log "nmsl.apk安装"
fi
find "$TMPDIR" -maxdepth 1 -name "*.apk" -type f 2>/dev/null | grep -v 'nmsl.apk' | while read; do
pm install-write "$b" "${REPLY##*/}" "$REPLY" &>/dev/null
echo_log "${REPLY##*/}安装"
done
pm install-commit "$b" &>/dev/null
echo_log "split Apk install"
;;
esac
fi
}
disable_verify() {
#Disable apk verification
settings put global verifier_verify_adb_installs 0 2>/dev/null
#Disable installation package verification
settings put global package_verifier_enable 0 2>/dev/null
#Unknown source
settings put secure install_non_market_apps 1 2>/dev/null
#Close play security verification
if [[ $(settings get global package_verifier_user_consent 2>/dev/null) != -1 ]]; then
settings put global package_verifier_user_consent -1 2>/dev/null
settings put global upload_apk_enable 0 2>/dev/null
echoRgb "PLAY security verification is turned on and has been turned off by the script to prevent apk installation failure" "3"
fi
# Set the file path
FILE="/data/data/com.android.vending/shared_prefs/finsky.xml"
if [[ -f $FILE ]]; then
# Extract the current auto_update_enabled value
CURRENT_VALUE="$(sed -n '/<boolean name="auto_update_enabled" /s/.*value="\([^"]*\)".*/\1/p' "$FILE")"
if [[ $CURRENT_VALUE = true ]]; then
sed -i '/<boolean name="auto_update_enabled" /s/value="true"/value="false"/' "$FILE"
[[ $(sed -n '/<boolean name="auto_update_enabled" /s/.*value="\([^"]*\)".*/\1/p' "$FILE") = false ]] && echoRgb "play auto-update is closed" "3"
echoRgb "Kill Google Play Store..."
am force-stop com.android.vending
else
if [[ $CURRENT_VALUE = "" ]]; then
sed -i '/<\/map>/i \ <boolean name="auto_update_enabled" value="false" />' "$FILE"
[[ $(sed -n '/<boolean name="auto_update_enabled" /s/.*value="\([^"]*\)".*/\1/p' "$FILE") = false ]] && echoRgb "auto_update_enabled has been inserted into false, play auto-update is closed" "3"
echoRgb "Kill Google Play Store..."
am force-stop com.android.vending
else
[[ $CURRENT_VALUE != false ]] && echoRgb "Unable to identify the current $CURRENT_VALUE value of play auto_update_enabled" "0"
fi
fi
fi
}
get_name(){
txt="$MODDIR/appList.txt"
txt2="$MODDIR/mediaList.txt"
txt3="$MODDIR/temp.txt"
txt="${txt/'/storage/emulated/'/'/data/media/'}"
if [[ $1 = Apkname ]]; then
rm -rf "$txt" "$txt2"
echoRgb "List all application names and custom directory compressed package names in all folders" "3"
fi
rgb_a=118
	user="$(echo "${0%}" | sed 's/.*\/Backup_zstd_\([0-9]*\).*/\1/')"
	[[ ! -f $txt3 ]] && {
	Apk_info="$(pm list packages -u --user "$user" | cut -f2 -d ':' | egrep -v 'ice.message|com.topjohnwu.magisk' | sort -u)"
	if [[ $Apk_info != "" ]]; then
	    [[ $Apk_info = *"Failure calling service package"* ]] && Apk_info="$(appinfo "user|system" "pkgName" 2>/dev/null | egrep -v 'ice.message|com.topjohnwu.magisk' | sort -u)"
	else
	    Apk_info="$(appinfo "user|system" "pkgName" 2>/dev/null | egrep -v 'ice.message|com.topjohnwu.magisk' | sort -u)"
	fi
	[[ $Apk_info = "" ]] && echoRgb "Apk_info variable is empty" "0" && exit
	starttime1="$(date -u "+%s")"
	find "$MODDIR" -maxdepth 2 -name "apk.*" -type f 2>/dev/null | sort | while read; do
		Folder="${REPLY%/*}"
		[[ $rgb_a -ge 229 ]] && rgb_a=118
		unset PackageName NAME DUMPAPK ChineseName apk_version Ssaid dataSize userSize obbSize
		if [[ -f $Folder/app_details.json ]]; then		    ChineseName="$(jq -r 'to_entries[] | select(.key != null).key' "$Folder/app_details.json" | head -n 1)"
		    PackageName="$(jq -r '.[] | select(.PackageName != null).PackageName' "$Folder/app_details.json")"
		    if [[ -f $Folder/Permissions ]]; then
		        unsetPermissions
		        . "$Folder/Permissions"
		        jq --arg packageName "$ChineseName" --argjson permissions "$(echo "$Permissions" | jq -nR '[inputs | select(length>0) | split(" ") | {(.[0]): .[-1]}] | add')" '.[$packageName] |= . + {permissions: $permissions}' "$Folder/app_details.json" > temp.json && cp temp.json "$Folder/app_details.json" && rm -rf "$Folder/Permissions" temp.json && echoRgb "Update $Folder/app_details.json"
		    fi
		else
		    if [[ -f $Folder/app_details ]]; then
		        . "$Folder/app_details" &>/dev/null
		        extra_content="{
                  \"$ChineseName\": {
                    \"PackageName\": \"$PackageName\",
                    \"apk_version\": \"$apk_version\",
                    \"Ssaid\": \"$Ssaid\"
                  },
                  \"data\": {
                    \"Size\": \"$dataSize\"
                  },
                  \"obb\": {
                    \"Size\": \"$obbSize\"
                  },
                  \"user\": {
                    \"Size\": \"$userSize\" }
}"
echo "{\n}">"$Folder/app_details.json"
jq --argjson new_content "$extra_content" '. += $new_content' "$Folder/app_details.json" > temp.json && cp temp.json "$Folder/app_details.json" && rm -rf temp.json "$Folder/app_details"
fi
fi
[[ ! -f $txt ]] && echo "#Applications that do not need to be restored, please use #comments at the beginning, for example: #Cool An com.coolapk.market" >"$txt"
if [[ $PackageName = "" || $ChineseName = "" ]]; then
echoRgb "${Folder##*/}Failed to obtain the package name, unzipping to obtain the package name..." "0"
rm -rf "$TMPDIR"/*
case ${REPLY##*.} in
zst) tar -I zstd -xmpf "$REPLY" -C "$TMPDIR" --wildcards --no-anchored 'base.apk' ;;
tar) tar -xmpf "$REPLY" -C "$TMPDIR" --wildcards --no-anchored 'base.apk' ;;
*)
echoRgb "${REPLY##*/} compressed package does not support decompression" "0"
Set_back_1
;;
esac
echo_log "${REPLY##*/} decompression"
if [[ $result = 0 ]]; then
if [[ -f $TMPDIR/base.apk ]]; then
DUMPAPK="$(appinfo3 "$TMPDIR/base.apk")"
if [[ $DUMPAPK != "" ]]; then
						app=($DUMPAPK $DUMPAPK)
						PackageName="${app[1]}"
						ChineseName="${app[2]}"
						rm -rf "$TMPDIR"/*
					else
						echoRgb "appinfo output failed" "0"
					fi
				fi
			fi
		fi
		if [[ $PackageName != "" && $ChineseName != "" ]]; then
		    if [[ $(echo "$Apk_info" | egrep -o "$PackageName") = "" ]]; then
		        echoRgb "$ChineseName no longer exists in $user"
    	        echo "$ChineseName $PackageName">>"$txt3"
    		fi
			case $1 in
			Apkname)
			    [[ -f $Folder/${PackageName}.sh ]] && rm -rf "$Folder/${PackageName}.sh"
		        [[ ! -f $Folder/recover.sh ]] && touch_shell "Restore2" "$Folder/recover.sh"
			    [[ ! -f $Folder/backup.sh ]] && touch_shell "backup" "$Folder/backup.sh" "backup_mode" "backup_mode=\"1\""
				echoRgb "$ChineseName $PackageName" && echo "$ChineseName $PackageName" >>"$txt" ;;
			convert)
				if [[ ${Folder##*/} = $PackageName ]]; then
				    DIR_NAME="${Folder%/*}/$ChineseName"
				    echoRgb "${Folder##*/} > $ChineseName"
				else
				    DIR_NAME="${Folder%/*}/$PackageName"
				    echoRgb "${Folder##*/} > $PackageName"
				fi
                if [[ -d $DIR_NAME ]]; then
                    i=1
                    NEW_DIR_NAME="${DIR_NAME}_${i}"
                    while [[ -d $NEW_DIR_NAME ]]; do
                        i=$((i + 1))
                        NEW_DIR_NAME="${DIR_NAME}_${i}"
                    done
                    DIR_NAME="$NEW_DIR_NAME"
                fi
                mv "$Folder" "$DIR_NAME" ;;
esac
fi
let rgb_a++
done
if [[ -d $MODDIR/Media ]]; then
echoRgb "Media folder exists" "2"
[[ ! -f $txt2 ]] && echo "#Folders that do not need to be restored, please use # comments at the beginning, such as: #Download" > "$txt2"
find "$MODDIR/Media" -maxdepth 1 -name "*.tar*" -type f 2>/dev/null | while read; do
echoRgb "${REPLY##*/}" && echo "${REPLY##*/}" >> "$txt2"
done
echoRgb "$txt2 regenerates" "1"
fi
}
if [[ -f $txt3 ]]; then
if [[ $(egrep -v '#|＃' "$txt3" 2>/dev/null | awk 'NF != 0 { count++ } END { print count }') != "" ]]; then
echoRgb "List the applications to be deleted....\n -$(cat "$txt3")"
case $Lo in
0|1)
echoRgb "After confirming that the list is correct, the volume is up to delete, and the volume is down to exit the script editing list" "2"
get_version "Delete" "Exit the script" && Delete_App="$branch" ;;
2)
Enter_options "After confirming that the list is correct, enter 1 to delete, enter 0 to exit the script editing list" "Delete" "Exit the script" && isBoolean "$parameter" "Delete_App" && Delete_App="$nsx" ;;
esac
if [[ $Delete_App = true ]]; then
		        i=1
		        r="$(egrep -v '#|#' "$txt3" 2>/dev/null | awk 'NF != 0 { count++ } END { print count }')"
		        while [[ $i -le $r ]]; do
		            name1="$(egrep -v '#|#' "$txt3" 2>/dev/null | sed -e '/^$/d' | sed -n "${i}p" | awk '{print $1}')"
    		        name2="$(egrep -v '#|#' "$txt3" 2>/dev/null | sed -e '/^$/d' | sed -n "${i}p" | awk '{print $2}')"
    		        Backup_folder="$MODDIR/$name1"
    		        [[ -d $Backup_folder ]] && rm -rf "$Backup_folder"
    		        echo "$(sed -e "s/$name1 $name2//g ; /^$/d" "$txt" 2>/dev/null)" >"$txt"
    		        let i++
    		    done
    		    rm -rf "$txt3"
    		else
    		    rm -rf "$txt3"
    		    exit 0
    	    fi
    	else
    	    rm -rf "$txt3"
    	fi
    fi
    endtime 1
	exit 0
}
self_test() {
	if [[ $(dumpsys deviceidle get charging) = false && $(dumpsys battery | awk '/level/{print $2}' | egrep -o '[0-9]+') -le 15 ]]; then
		echoRgb "Battery$(dumpsys battery | awk '/level/{print $2}' | egrep -o '[0-9]+')% is too low and not charged\n -To prevent the backup file or restore the file from being damaged due to forced shutdown due to low power\n -Please connect the charger before backing up" "0" && exit 2
fi
}
Validation_file() {
MODDIR_NAME="${1%/*}"
MODDIR_NAME="${MODDIR_NAME##*/}"
FILE_NAME="${1##*/}"
echoRgb "Validation $FILE_NAME"
case ${FILE_NAME##*.} in
zst) zstd -t "$1" 2>/dev/null ;;
tar) tar -tf "$1" &>/dev/null ;;
esac
echo_log "Validation"
}
Check_archive() {
starttime1="$(date -u "+%s")"
	error_log="$TMPDIR/error_log"
	rm -rf "$error_log"
	FIND_PATH="$(find "$1" -maxdepth 3 -name "*.tar*" -type f 2>/dev/null | sort)"
	i=1
	r="$(find "$MODDIR" -maxdepth 2 -name "app_details.json" -type f 2>/dev/null | wc -l)"
	find "$MODDIR" -maxdepth 2 -name "app_details.json" -type f 2>/dev/null | sort | while read; do
		REPLY="${REPLY%/*}"
		echoRgb "Examine the $i/$rth folder, leaving $((r - i))" "3"
		echoRgb "validation:${REPLY##*/}"
		find "$REPLY" -maxdepth 1 -name "*.tar*" -type f 2>/dev/null | sort | while read; do
Validation_file "$REPLY"
[[ $result != 0 ]] && echo "$REPLY">>"$error_log"
done
echoRgb "$((i * 100 / r))%"
let i++ nskg++
done
endtime 1
[[ -f $error_log ]] && echoRgb "The following is the failed file\n $(cat "$error_log")" || echoRgb "Congratulations~~ All validations passed" 
rm -rf "$error_log"
}
Set_screen_pause_seconds () {
if [[ $1 = on ]]; then
#Get the number of seconds for the screen to pause when there is no operation set by the system
if [[ $Get_dark_screen_seconds = "" ]]; then
Get_dark_screen_seconds="$(settings get system screen_off_timeout)"
#Set the screen off after 30 minutes
settings put system screen_off_timeout 1800000
echo_log "Set the screen off time for 30 minutes when no operation is performed"
fi
[[ $setDisplayPowerMode = true ]] && {
setDisplay 0
echo_log "Set the screen state to false"
}
elif [[ $1 = off ]]; then
if [[ $Get_dark_screen_seconds != "" ]]; then
settings put system screen_off_timeout "$Get_dark_screen_seconds"
echo_log "Set the screen off time for no operation to $Get_dark_screen_seconds"
input keyevent 224
fi
[[ $setDisplayPowerMode = true ]] && {
setDisplay 2
echo_log "Set screen state true"
        }
    fi
}
restore_permissions () {
    echoRgb "Restore permissions"
    appops reset --user "$user" "$name2" &>/dev/null
    true_permissions="$(jq -r 'to_entries[] | select(.value.permissions != null) | .value.permissions | to_entries | map(select(.value | startswith("true")) | .key) | join(" ")' "$app_details")"
    false_permissions="$(jq -r 'to_entries[] | select(.value.permissions != null) | .value.permissions | to_entries | map(select(.value | startswith("false")) | .key) | join(" ")' "$app_details")"
	Set_Ops_permissions="$(jq -r '.[] | select(.permissions != null).permissions | to_entries | map(.value | split(" ")) | map(select(.[1] != "-1")) | map(.[1:]) | flatten | join(" ")' "$app_details")"
[[ $true_permissions != "" ]] && {
Set_true_Permissions "$name2" "$true_permissions" &>/dev/null
[[ $? != 0 ]] && echo_log "Set allowed permissions"
}
[[ $false_permissions != "" ]] && {
Set_false_Permissions "$name2" "$false_permissions" &>/dev/null
[[ $? != 0 ]] && echo_log "Set denied permissions"
}
[[ $Set_Ops_permissions != "" ]] && {
    Set_Ops "$name2" "$Set_Ops_permissions"
    [[ $? != 0 ]] && echo_log "Set ops permissions"
    }
}
Background_application_list() {
    if [[ $Background_apps_ignore = true ]]; then
        unset Backstage apk_path3
	    #Get the background
	    if [[ $(dumpsys activity activities | awk -F 'packageName=' '/packageName=/{split($2, a, " "); print a[1]}' | sort | uniq) != "" ]]; then
		    apk_path3="$(echo "$(pm path --user "$user" "$(dumpsys activity activities | awk -F 'packageName=' '/packageName=/{split($2, a, " "); print a[1]}' | sort | uniq | head -1)" 2>/dev/null | cut -f2 -d ':')" | head -1)"
            if [[ -d ${apk_path3%/*} ]]; then
                Backstage="$(dumpsys activity activities | awk -F 'packageName=' '/packageName=/{split($2, a, " "); print a[1]}' | sort | uniq)"
            else
                if [[ $(am stack list | awk '/taskId/&&!/unknown/{split($2, a, "/"); print a[1]}') != "" ]]; then
		            apk_path3="$(echo "$(pm path --user "$user" "$(am stack list | awk '/taskId/&&!/unknown/{split($2, a, "/"); print a[1]}' | head -1)" 2>/dev/null | cut -f2 -d ':')" | head -1)"
                    [[ -d ${apk_path3%/*} ]] && Backstage="$(am stack list | awk '/taskId/&&!/unknown/{split($2, a, "/"); print a[1]}')"
                fi
            fi
        else
            if [[ $(am stack list | awk '/taskId/&&!/unknown/{split($2, a, "/"); print a[1]}') != "" ]]; then
		        apk_path3="$(echo "$(pm path --user "$user" "$(am stack list | awk '/taskId/&&!/unknown/{split($2, a, "/"); print a[1]}' | head -1)" 2>/dev/null | cut -f2 -d ':')" | head -1)"
[[ -d ${apk_path3%/*} ]] && Backstage="$(am stack list | awk '/taskId/&&!/unknown/{split($2, a, "/"); print a[1]}')"
fi
fi
[[ ! -d ${apk_path3%/*} ]] && {
echoRgb "Failed to get the current background application" "0" && unset Backstage
}
fi
}
case $operate in
backup)
kill_Serve
self_test
case $MODDIR in
/storage/emulated/0/Android/* | /data/media/0/Android/* | /sdcard/Android/*) echoRgb "Do not backup in $MODDIR" "0" && exit 2 ;;
esac
case $Compression_method in
zstd | Zstd | ZSTD | tar | Tar | TAR) ;;
*) echoRgb "$Compression_method is an unsupported compression algorithm" "0" && exit 2 ;;
esac
#Verify that the options are correct
case $Lo in
0)
[[ $Backup_Mode != "" ]] && isBoolean "$Backup_Mode" "Backup_Mode" && Backup_Mode="$nsx" || {
echoRgb "Select backup mode\n - backup applications + data on the upper volume, only applications without data on the lower volume" "2"
get_version "applications + data" "application only" && Backup_Mode="$branch"
}
if [[ $Backup_Mode = true ]]; then
if [[ $(echo "$blacklist" | egrep -v '#|＃' | wc -l) -gt 0 ]]; then
if [[ $blacklist_mode != "" ]]; then
isBoolean "$blacklist_mode" "blacklist_mode" && blacklist_mode="$nsx"
else
echoRgb "Select blacklist mode\n - No backup on volume, only backup installation files on volume\n - Warning! " "2"
get_version "No backup" "Backup installation file" && blacklist_mode="$branch"
fi
fi
fi
if [[ $Backup_Mode = true ]]; then
[[ $Backup_obb_data != "" ]] && isBoolean "$Backup_obb_data" "Backup_obb_data" && Backup_obb_data="$nsx" || {
echoRgb "Whether to back up external data, such as the data package of Genshin Impact\n -Backup on the volume, not on the volume" "2"
get_version "Backup" "No backup" && Backup_obb_data="$branch"
}
[[ $Backup_user_data != "" ]] && isBoolean "$Backup_user_data" "Backup_user_data" && Backup_user_data="$nsx" || {
echoRgb "Whether to back up user data\n -Backup on the volume, not on the volume" "2"
get_version "Backup" "Do not back up" && Backup_user_data="$branch"
}
else
Backup_user_data="false"
Backup_obb_data="false"
fi
[[ $backup_media != "" ]] && isBoolean "$backup_media" "backup_media" && backup_media="$nsx" || {
echoRgb "Whether to back up the custom directory after all applications are backed up\n -Backup on the volume, not on the volume" "2"
get_version "Backup" "Do not back up" && backup_media="$branch"
}
[[ $setDisplayPowerMode != "" ]] && isBoolean "$setDisplayPowerMode" "setDisplayPowerMode" && setDisplayPowerMode="$nsx" || {
echoRgb "Turn off screen after application backup starts\n -Turn off when volume is up, not when volume is down" "2"
get_version "Turn off" "Not turn off" && setDisplayPowerMode="$branch"
}
[[ $Background_apps_ignore != "" ]] && isBoolean "$Background_apps_ignore" "Background_apps_ignore" && Background_apps_ignore="$nsx" || {
echoRgb "Ignore backup if there is a process\n -Ignore when volume is up, backup when volume is down" "2"
get_version "Ignore" "Backup" && Background_apps_ignore="$branch"
} ;;
1)
[[ $Backup_Mode = "" ]] && {
echoRgb "Select backup mode\n -Backup applications + data on the volume, only applications without data on the volume" "2"
get_version "applications + data" "only applications" && Backup_Mode="$branch"
} || isBoolean "$Backup_Mode" "Backup_Mode" && Backup_Mode="$nsx"
if [[ $Backup_Mode = true ]]; then
if [[ $(echo "$blacklist" | egrep -v '#|＃' | wc -l) -gt 0 ]]; then
[[ $blacklist_mode = "" ]] && {
echoRgb "Select blacklist mode\n -Do not backup on the volume, only backup the installation file on the volume" "2"
get_version "Do not backup" "Backup installation file" && blacklist_mode="$branch"
} || isBoolean "$blacklist_mode" "blacklist_mode" && blacklist_mode="$nsx"
fi
[[ $Backup_obb_data = "" ]] && {
echoRgb "Whether to back up external data, such as the data package of Genshin Impact\n -Backup on the volume, not on the volume" "2"
get_version "Backup" "No backup" && Backup_obb_data="$branch"
} || isBoolean "$Backup_obb_data" "Backup_obb_data" && Backup_obb_data="$nsx"
[[ $Backup_user_data = "" ]] && {
echoRgb "Whether to back up user data\n -Backup on the volume, not on the volume" "2"
get_version "Backup" "No backup" && Backup_user_data="$branch"
} || isBoolean "$Backup_user_data" "Backup_user_data" && Backup_user_data="$nsx"
fi
[[ $backup_media = "" ]] && {
echoRgb "Whether to back up the custom directory after all application backups are completed\n -Backup on volume up, not on volume down" "2"
get_version "Backup" "Not backed up" && backup_media="$branch"
} || isBoolean "$backup_media" "backup_media" && backup_media="$nsx"
[[ $setDisplayPowerMode = "" ]] && {
echoRgb "Close the screen after application backup starts\n -Close on volume up, not on volume down" "2"
get_version "Close" "Not closed" && setDisplayPowerMode="$branch"
} || isBoolean "$setDisplayPowerMode" "setDisplayPowerMode" && setDisplayPowerMode="$nsx"
[[ $Background_apps_ignore = "" ]] && {
echoRgb "Ignore backup if process exists\n - ignore on volume, backup on volume" "2"
get_version "Ignore" "Backup" && Background_apps_ignore="$branch"
} || isBoolean "$Background_apps_ignore" "Background_apps_ignore" && Background_apps_ignore="$nsx"
;;
2)
[[ $Backup_Mode = "" ]] && {
Enter_options "Enter 1 to backup application + data, enter 0 to backup only application without data" "Application + data" "Application only" && isBoolean "$parameter" "Backup_Mode" && Backup_Mode="$nsx"
} || {
isBoolean "$Backup_Mode" "Backup_Mode" && Backup_Mode="$nsx"
}
if [[ $Backup_Mode = true ]]; then
[[ $(echo "$blacklist" | egrep -v '#|＃' | wc -l) -gt 0 ]] && {
[[ $blacklist_mode = "" ]] && {
Enter_options "Select blacklist mode. Enter 1 to not back up, enter 0 to back up the installation file" "Do not back up" "Apply only to the installation file" && isBoolean "$parameter" "blacklist_mode" && blacklist_mode="$nsx"
} || {
isBoolean "$blacklist_mode" "blacklist_mode" && blacklist_mode="$nsx"
}
}
[[ $Backup_obb_data = "" ]] && {
Enter_options "Whether to back up external data, such as the data package of Genshin Impact\n -Enter 1 to backup, enter 0 to not backup" "Backup" "No backup" && isBoolean "$parameter" "Backup_obb_data" && Backup_obb_data="$nsx"
} || {
isBoolean "$Backup_obb_data" "Backup_obb_data" && Backup_obb_data="$nsx"
}
[[ $Backup_user_data = "" ]] && {
Enter_options "Whether to back up user data, enter 1 to backup, enter 0 to not backup" "Backup" "No backup" && isBoolean "$parameter" "Backup_user_data" && Backup_user_data="$nsx"
} || {
isBoolean "$Backup_user_data" "Backup_user_data" && Backup_user_data="$nsx"
}
fi
[[ $backup_media = "" ]] && {
Enter_options "Whether to back up the custom directory after all application backups are completed\n - Enter 1 to backup, 0 not to backup" "Backup" "Not backup" && isBoolean "$parameter" "backup_media" && backup_media="$nsx"
} || {
isBoolean "$backup_media" "backup_media" && backup_media="$nsx"
}
[[ $setDisplayPowerMode = "" ]] && {
Enter_options "Close the screen after application backup starts\n - Enter 1 to close, 0 not to close" "Close" "Not close" && isBoolean "$parameter" "setDisplayPowerMode" && setDisplayPowerMode="$nsx"
} || {
isBoolean "$setDisplayPowerMode" "setDisplayPowerMode" && setDisplayPowerMode="$nsx"
}
[[ $Background_apps_ignore = "" ]] && {
Enter_options "Ignore backup if there is a process\n - Enter 1 for no backup, 0 for backup" "Ignore" "Backup" && isBoolean "$parameter" "Background_apps_ignore" && Background_apps_ignore="$nsx"
} || {
isBoolean "$Background_apps_ignore" "Background_apps_ignore" && Background_apps_ignore="$nsx"
} ;;
*) echoRgb "$conf_path Lo=$Lo is incorrectly filled in, the correct value is 0 1 2" "0" && exit 2 ;;
esac
i=1
#Data directory
if [[ $list_location != "" ]]; then
if [[ ${list_location:0:1} = / ]]; then
txt="$list_location"
else
txt="$MODDIR/$list_location"
echoRgb "$txt"
fi
else
txt="$MODDIR/appList.txt"
fi
#txt="${txt/'/storage/emulated/'/'/data/media/'}"
[[ ! -f $txt ]] && echoRgb "Please execute\"Generate application list.sh\"Get the application list and back it up" "0" && exit 1
TXT_NAME="${txt##*/}"
case ${TXT_NAME##*.} in
txt) ;;
*) echoRgb "$txt is not a script reading format" "0" && exit 2 ;;
esac
sort -u "$txt" -o "$txt" &>/dev/null
data="$MODDIR"
hx="local"
echoRgb "The script is affected by the kernel mechanism. The IO performance is seriously affected after the screen is off.\n - Please do not close the terminal or back up the screen. If you need to terminate the script\n - Please execute the termination script.sh to stop" "3"
backup_path
echoRgb "Configuration details:\n - Compression method: $Compression_method\n - Volume key confirmation: $Lo\n - Update: $update\n - Backup mode: $Backup_Mode\n - Backup external data: $Backup_obb_data\n - Backup user data: $Backup_user_data\n - Custom directory backup: $backup_media\n - Ignore backup when there is a process: $Background_apps_ignore\n - Turn off the screen: $setDisplayPowerMode"
	D="1"
	Apk_info="$(pm list packages -u --user "$user" | cut -f2 -d ':' | egrep -v 'ice.message|com.topjohnwu.magisk' | sort -u)"
	if [[ $Apk_info != "" ]]; then
	    [[ $Apk_info = *"Failure calling service package"* ]] && Apk_info="$(appinfo "user|system" "pkgName" 2>/dev/null | egrep -v 'ice.message|com.topjohnwu.magisk' | sort -u)"
	else
	    Apk_info="$(appinfo "user|system" "pkgName" 2>/dev/null | egrep -v 'ice.message|com.topjohnwu.magisk' | sort -u)"
	fi
	[[ $Apk_info = "" ]] && echoRgb "Apk_info variable is empty" "0" && exit
[[ $backup_mode = "" ]] && {
echoRgb "Check if there are uninstalled applications in the backup list" "3"
echoRgb "Check if the backup list has updated applications" "3"
while read -r ; do
if [[ $(echo "$REPLY" | sed -E 's/^[ \t]*//; /^[ \t]*[#＃!]/d') != "" ]]; then
app=($REPLY $REPLY)
if [[ ${app[1]} != "" && ${app[2]} != "" ]]; then
if [[ $(echo "$Apk_info" | egrep -o "${app[1]}") != "" ]]; then
[[ $Tmplist = "" ]] && Tmplist='#Applications that do not need to be backed up, please use it at the beginning#Comment For example: #Cool Security com.coolapk.market (ignore installation package and data)\n#Applications that do not need to backup data, please use it at the beginning!Comment For example: !Cool Security com.coolapk.market (only ignore data)'
Tmplist="$Tmplist\n$REPLY"
if [[ $Update_backup != "" ]]; then
Backup_folder="$Backup/${app[2]}"
app_details="$Backup_folder/app_details.json"
if [[ -d $Backup_folder ]]; then
apk_version="$(jq -r '.[] | select(.apk_version != null).apk_version' "$app_details")"
apk_version2="$(pm list packages --show-versioncode --user "$user" "${app[1]}" 2>/dev/null | cut -f3 -d ':' | head -n 1)"
[[ $apk_version != $apk_version2 ]] && {
[[ $Tmplist2 = "" ]] && Tmplist2="$REPLY" || Tmplist2="$Tmplist2\n$REPLY"
}
fi
fi
else
echoRgb "$REPLY does not exist in the system, delete from the list" "0"
fi
fi
else
Tmplist="$Tmplist\n$REPLY"
fi
done < "$txt"
}
[[ $Tmplist != "" ]] && echo "$Tmplist" | sed -e '/^$/d' | sort>"$txt"
if [[ $Tmplist2 != "" ]]; then
if [[ $Update_backup != "" ]]; then
cat "$txt">"${txt%/*}/txt2"
echo "$Tmplist2" | sed -e '/^$/d' | sort>"$txt"
fi
else
[[ $Update_backup != "" ]] && echoRgb "Application currently not updated" "0" && exit 0
fi
r="$(egrep -v '#|＃' "$txt" 2>/dev/null | awk 'NF != 0 { count++ } END { print count }')"
[[ $backup_mode != "" ]] && r=1
[[ $r = "" && $backup_mode = "" ]] && echoRgb "$MODDIR_NAME/appList.txt is empty or the package name is commented. Backup ghost\n - Check whether it is commented or execute $MODDIR_NAME/Generate application list.sh" "0" && exit 1
if [[ $Backup_Mode = true ]]; then
[[ $Backup_user_data = false ]] && echoRgb "Current $MODDIR_NAME/backup_settings.conf\n -Backup_user_data=0 will not back up user data" "0"
[[ $Backup_obb_data = false ]] && echoRgb "Current $MODDIR_NAME/backup_settings.conf\n -Backup_obb_data=0 will not back up external data" "0"
fi
[[ $backup_media = false ]] && echoRgb "Current $MODDIR_NAME/backup_settings.conf\n -backup_media=0 will not back up custom folders" "0"
txt2="$Backup/appList.txt"
[[ ! -f $txt2 ]] && echo "#Applications that do not need to be restored, please use #comments at the beginning. For example: #Cool An com.coolapk.market">"$txt2"
[[ ! -d $Backup/tools ]] && cp -r "$tools_path" "$Backup"
[[ ! -f $Backup/Restore backup.sh ]] && touch_shell "Restore" "$Backup/Restore backup.sh"
[[ ! -f $Backup/Terminate script.sh ]] && cp -r "$MODDIR/Terminate script.sh" "$Backup/Terminate script.sh"
[[ ! -f $Backup/Regenerate application list.sh ]] && touch_shell "dumpname" "$Backup/Regenerate application list.sh"
[[ ! -f $Backup/Convert folder name.sh ]] && touch_shell "convert" "$Backup/Convert folder name.sh"
[[ ! -f $Backup/Compressed file integrity check.sh ]] && touch_shell "check_file" "$Backup/Compressed file integrity check.sh"
[[ ! -d $Backup/modules ]] && mkdir -p "$Backup/modules" && echoRgb "$Backup/modules has been created successfully\n -Please place the modules that need to be flashed during recovery as needed. They will be automatically flashed in batches" "1"
[[ -d $Backup/Media ]] && touch_shell "Restore3" "$Backup/restore custom folder.sh"
	[[ ! -f $Backup/restore_settings.conf ]] && update_Restore_settings_conf>"$Backup/restore_settings.conf"
	if [[ -d $Backup/tools ]]; then
	    find "$Backup/tools" -maxdepth 1 -type f | while read; do
	        Tools_FILE_NAME="${REPLY##*/}"
	        filesha256="$(sha256sum "$tools_path/$Tools_FILE_NAME" 2>/dev/null | cut -d" " -f1)"
	        filesha256_1="$(sha256sum "$REPLY" 2>/dev/null | cut -d" " -f1)"
	        if [[ $filesha256 != $filesha256_1 ]]; then
	            cp -r "$tools_path/$Tools_FILE_NAME" "$REPLY"
echoRgb "Update $REPLY"
fi
done
fi
filesize="$(find "$Backup" -type f -printf "%s\n" | awk '{s+=$1} END {print s}')"
Quantity=0
#Start looping the data in $txt for backup
#Record start time
en=118
echo "$script">"$TMPDIR/scriptTMP" && echo "$script">"$TMPDIR/scriptTMP"
osn=0; osj=0; osk=0
#Get the accessibility that has been turned on
var="$(settings get secure enabled_accessibility_services 2>/dev/null)"
#Get the default keyboard
keyboard="$(settings get secure enabled_accessibility_services 2>/dev/null)" default_input_method 2>/dev/null)"
    Set_screen_pause_seconds on
	[[ $(egrep -v '#|#' "$txt" 2>/dev/null | sed -e '/^$/d' | awk '{print $2}' | grep -w "^${keyboard%/*}$") != ${keyboard%/*} ]] && unset keyboard
	{
	starttime1="$(date -u "+%s")"
	TIME="$starttime1"
	notification "101" "Start backup"
	while [[ $i -le $r ]]; do
		[[ $en -ge 229 ]] && en=118
		unset name1 name2 apk_path apk_path2
		if [[ $backup_mode = "" ]]; then
    		name1="$(egrep -v '#|#' "$txt" 2>/dev/null | sed -e '/^$/d' | sed -n "${i}p" | awk '{print $1}')"
    		name2="$(egrep -v '#|#' "$txt" 2>/dev/null | sed -e '/^$/d' | sed -n "${i}p" | awk '{print $2}')"
        else
            ChineseName="$(jq -r 'to_entries[] | select(.key != null).key' "${0%/*}/app_details.json" | head -n 1)"
		    PackageName="$(jq -r '.[] | select(.PackageName != null).PackageName' "${0%/*}/app_details.json")" name1="$ChineseName"
name2="$PackageName"
fi
[[ $name2 = "" || $name1 = "" ]] && echoRgb "Warning! Failed to obtain the package name of appList.txt, there may be problems with the modification" "0" && exit 1
apk_path="$(pm path --user "$user" "$name2" 2>/dev/null | cut -f2 -d ':')"
apk_path2="$(echo "$apk_path" | head -1)"
apk_path2="${apk_path2%/*}"
if [[ -d $apk_path2 ]]; then
echoRgb "Backup $i/$r applications, $((r - i)) left" "3"
echoRgb "Backup $name1 \"$name2\"" "2"
notification "101" "Backup the $i/$rth application. $((r - i)) applications are left.
Backup $name1 \"$name2\""
unset Backup_folder ChineseName PackageName nobackup No_backupdata result apk_version apk_version2 zsize zmediapath Size data_path Ssaid ssaid Permissions
nobackup="false"
Background_application_list
[[ $Backstage != "" && $(echo "$Backstage" | egrep -w "^$name2$") != "" ]] && echoRgb "$name1 exists in the background. Ignore backup" "0" && nobackup="true"
if [[ $Backup_Mode = true ]]; then
if [[ $name1 = !* || $name1 = ! * ]]; then
name1="$(echo "$name1" | sed 's/!//g ; s/！//g')"
echoRgb "Skip backup of all data" "0"
No_backupdata=1
fi
if [[ $(echo "$blacklist" | grep -w "^$name2$") = $name2 ]]; then
if [[ $blacklist_mode = true ]]; then
echoRgb "Blacklist application skips backup" "0"
nobackup="true"
else
echoRgb "Blacklist application skips backup of all data" "0"
fi
No_backupdata=1
fi
fi
Backup_folder="$Backup/$name1"
app_details="$Backup_folder/app_details.json"
if [[ -f $app_details ]]; then
PackageName="$(jq -r '.[] | select(.PackageName != null).PackageName' "$app_details")"
[[ $PackageName != $name2 ]] && jq --arg name2 "$name2" 'walk(if type == "object" and .PackageName then .PackageName = $name2 else . end)' "$app_details" > temp.json && cp temp.json "$app_details" && rm -rf temp.json
fi
[[ $hx = USB && $PT = "" ]] && echoRgb "The USB drive was accidentally disconnected. Please check the stability" "0" && exit 1
starttime2="$(date -u "+%s")"
[[ $name2 = com.tencent.mobileqq ]] && echoRgb "QQ may fail to restore the backup or lose the chat history. Please use the application you trust to back up" "0"
[[ $name2 = com.tencent.mm ]] && echoRgb "WX may fail to restore the backup or lose the chat history. Please use the application you trust to back up" "0"
apk_number="$(echo "$apk_path" | wc -l)"
if [[ $nobackup != true ]]; then
if [[ $apk_number = 1 ]]; then
Backup_apk "Non-Split Apk" "3"
else
Backup_apk "Split Apk supports backup" "3"
fi
if [[ $result = 0 && $No_backupdata = "" ]]; then
if [[ $Backup_Mode = true ]]; then
if [[ $Backup_obb_data = true ]]; then
if [[ $name2 != *mt* ]]; then
#Backup data data
Backup_data "data"
#Backup obb data
Backup_data "obb"
else
echoRgb "$name1 cannot be backed up" "0"
fi
fi
#Backup user data
[[ $name2 != *mt* ]] && {
[[ $Backup_user_data = true ]] && {
Backup_data "user"
Backup_data "user_de"
}
}
[[ $name2 = github.tornaco.android.thanos ]] && Backup_data "thanox" "$(find "/data/system" -name "thanos"* -maxdepth 1 -type d 2>/dev/null)"
[[ $name2 = cn.myflv.noactive ]] && Backup_data "NoActive" "$(find "/data/system" -name "NoActive_"* -maxdepth 1 -type d 2>/dev/null)"
        				[[ $name2 = moe.shizuku.redirectstorage ]] && Backup_data "storage-isolation" "/data/adb/storage-isolation"
        		    fi
    			fi
    			[[ -f $Backup_folder/${name2}.sh ]] && rm -rf "$Backup_folder/${name2}.sh"
    		    [[ ! -f $Backup_folder/recover.sh ]] && touch_shell "Restore2" "$Backup_folder/recover.sh"
    			[[ ! -f $Backup_folder/backup.sh ]] && touch_shell "backup" "$Backup_folder/backup.sh" "backup_mode" "backup_mode=\"1\""
fi
endtime 2 "$name1 backup" "3"
lxj="$(echo "$Occupation_status" | awk '{print $3}' | sed 's/%//g')"
echoRgb "Completed $((i * 100 / r))% $hx$(echo "$Occupation_status" | awk 'END{print "Remaining:"$1" Usage rate:"$2}')" "3"
rgb_d="$rgb_a"
rgb_a=188
echoRgb "_________________$(endtime 1 "Already")___________________"
rgb_a="$rgb_d"
else
echoRgb "$name1[$name2] is not in the installation list, is the backup lonely? " "0"
fi
if [[ $i = $r ]]; then
endtime 1 "Apply backup" "3"
#Set accessibility switch
if [[ $var != "" ]]; then
if [[ $var != null ]]; then
settings put secure enabled_accessibility_services "$var" &>/dev/null
echo_log "Set accessibility"
settings put secure accessibility_enabled 1 &>/dev/null
echo_log "Turn on accessibility switch"
fi
fi
#Set keyboard
if [[ $keyboard != "" ]]; then
ime enable "$keyboard" &>/dev/null
ime set "$keyboard" &>/dev/null
settings put secure default_input_method "$keyboard" &>/dev/null
echo_log "Set keyboard $(appinfo2 "${keyboard%/*}" 2>/dev/null)"
fi
update_apk2="${update_apk2:="No update yet"}"
add_app2="${add_app2:="No update yet"}"
echoRgb "\n -Updated apk=\"$osn\"\n -Added backup=\"$osk\"\n -apk version number unchanged=\"$osj\"\n -The following are applications with changed version numbers\n$update_apk2\n -Added backup....\n$add_app2\n -Applications containing SSAID\n$SSAID_apk2" "3"
notification "101" "app backup completed $(endtime 1 "application backup" "3")"
echo "$(sort "$txt2" | sed -e '/^$/d')" >"$txt2"
[[ -e ${txt%/*}/txt2 ]] && cat "${txt%/*}/txt2">"$txt" && rm -rf "${txt%/*}/txt2"
if [[ $backup_media = true && $backup_mode = "" ]]; then
A=1
B="$(echo "$Custom_path" | egrep -v '#|＃' | awk 'NF != 0 { count++ } END { print count }')"
if [[ $B != "" ]]; then
echoRgb "Backup completed, backup multimedia" "1"
notification "102" "Media backup starts"
starttime1="$(date -u "+%s")"
Backup_folder="$Backup/Media"
[[ ! -f $Backup/Restore custom folder.sh ]] && touch_shell "Restore3" "$Backup/Restore custom folder.sh"
[[ ! -d $Backup_folder ]] && mkdir -p "$Backup_folder"
app_details="$Backup_folder/app_details.json"
[[ ! -f $app_details ]] && echo "{\n}">"$app_details"
mediatxt="$Backup/mediaList.txt"
[[ ! -f $mediatxt ]] && echo "#Please use #comment at the beginning of the folder that does not need to be restored, such as: #Download" > "$mediatxt"
echo "$Custom_path" | sed -e '/^#/d; /^$/d; s/\/$//' | while read; do
echoRgb "Backup folder $A/$B, $((B - A)) remaining" "3"
notification "102" "Backup folder $A/$B, $((B - A)) remaining"
starttime2="$(date -u "+%s")"
if [[ ${REPLY##*/} = adb ]]; then
if [[ $ksu != ksu ]]; then
echoRgb "Magisk adb"
Backup_data "${REPLY##*/}" "$REPLY"
else
echoRgb "KernelSU adb does not support backup" "0"
Set_back_0
fi
else
Backup_data "${REPLY##*/}" "$REPLY"
fi
endtime 2 "${REPLY##*/} backup" "1"
echoRgb "Complete $((A * 100 / B))% $hx$(echo "$Occupation_status" | awk 'END{print "Remaining:"$1" Usage:"$2}')" "2"
rgb_d="$rgb_a"
rgb_a=188
echoRgb "_________________$(endtime 1 "Already")___________________"
rgb_a="$rgb_d" && let A++
done
echoRgb "Directory↓↓↓\n -$Backup_folder"
notification "102" "Media backup completed $(endtime 1 "Custom backup")"
endtime 1 "Custom backup"
else
echoRgb "Custom path is empty and cannot be backed up" "0"
fi
fi
fi
let i++ en++ nskg++
done
Set_screen_pause_seconds off
[[ $user != 0 ]] && am stop-user "$user"
rm -rf "$TMPDIR/scriptTMP"
Calculate_size "$Backup"
echoRgb "Batch backup completed"
echoRgb "Backup end time $(date +"%Y-%m-%d %H:%M:%S")"
starttime1="$TIME"
endtime 1 "Batch backup start to end"
notification "105" "Backup completed $(endtime 1 "Batch backup start to end")"
} &
wait && exit
;;
dumpname)
get_name "Apkname"
;;
convert)
get_name "convert"
;;
check_file)
Check_archive "$MODDIR"
;;
Restore|Restore2)
kill_Serve
self_test
disable_verify
[[ ! -d $path2 ]] && echoRgb "The user directory does not exist on the device" "0" && exit 1
if [[ $operate = Restore ]]; then
echoRgb "If you regret and want to terminate the script, please leave this script as soon as possible and click $MODDIR_NAME/Terminate Script.sh\n - Otherwise, the script will continue to execute until the end" "0"
echoRgb "If there are a lot of prompts that the folder cannot be found, please execute $MODDIR_NAME/Convert Folder Name.sh"
txt="$MODDIR/appList.txt"
[[ ! -f $txt ]] && echoRgb "Please execute\"Regenerate Application List.sh\" to obtain the application list and then restore it" "0" && exit 2
sort -u "$txt" -o "$txt" 2>/dev/null
i=1
r="$(egrep -v '#|＃' "$txt" 2>/dev/null | awk 'NF != 0 { count++ } END { print count }')"
[[ $r = "" ]] && echoRgb "appList.txt package name is empty or commented\n - Please execute \"Regenerate application list.sh\" to obtain the application list and then restore" "0" && exit 1
Backup_folder2="$MODDIR/Media"
Backup_folder3="$MODDIR/modules"
#Verify that the options are correct
case $Lo in
0)
[[ $recovery_mode != "" ]] && isBoolean "$recovery_mode" "recovery_mode" && recovery_mode="$nsx" || {
echoRgb "Select application recovery mode\n -Only restore the volume if it is not installed, and restore it completely"
get_version "Restore not installed" "Full recovery" && recovery_mode="$branch"
}
[[ $setDisplayPowerMode != "" ]] && isBoolean "$setDisplayPowerMode" "setDisplayPowerMode" && setDisplayPowerMode="$nsx" || {
echoRgb "Close the screen when the application is restored\n -Only close the volume if it is not installed, and do not close it if it is not installed"
get_version "Close" "Do not close" && setDisplayPowerMode="$branch"
}
Get_user="$(echo "$MODDIR" | rev | cut -d '/' -f1 | cut -d '_' -f1 | rev | egrep -o '[0-9]+')"
if [[ $Get_user != $user ]]; then
echoRgb "Detect that the current user $user is different from the user of the recovery folder: $Get_user, the volume continues to be restored, the volume does not recover and the script is exited"
get_version "Restore installation" "Do not restore installation" && recovery_mode2="$branch"
fi
if [[ -d $Backup_folder2 ]]; then
[[ $media_recovery != "" ]] && isBoolean "$media_recovery" "media_recovery" && media_recovery="$nsx" || {
echoRgb "Whether to restore multimedia data\n - Restore on the volume, not on the volume" "2"
get_version "Restore media data" "Skip to restore media data" && media_recovery="$branch"
}
fi
if [[ -d $Backup_folder3 && $(find "$Backup_folder3" -maxdepth 1 -name "*.zip*" -type f 2>/dev/null | wc -l) != 0 ]]; then
[[ $modules_recovery != "" ]] && isBoolean "$modules_recovery" "modules_recovery" && modules_recovery="$nsx" || {
echoRgb "Whether to flash Magisk module\n - Flash when volume is up, do not flash when volume is down" "2"
get_version "Flash module" "Skip flashing module" && modules_recovery="$branch"
}
fi
[[ $Background_apps_ignore != "" ]] && isBoolean "$Background_apps_ignore" "Background_apps_ignore" && Background_apps_ignore="$nsx" || {
echoRgb "Ignore recovery if process exists\n -Ignore if volume is up, restore if volume is down" "2"
get_version "Ignore" "Restore" && Background_apps_ignore="$branch"
} ;;
1)
echoRgb "Select application recovery mode\n -Only restore not installed if volume is up, restore all if volume is down"
get_version "Restore not installed" "Full recovery" && recovery_mode="$branch"
echoRgb "Close screen when application is restored\n -Close if volume is up, not closed if volume is down"
get_version "Close" "Do not close" && setDisplayPowerMode="$branch"
Get_user="$(echo "$MODDIR" | rev | cut -d '/' -f1 | cut -d '_' -f1 | rev | egrep -o '[0-9]+')"
    	    if [[ $Get_user != $user ]]; then
echoRgb "Detect that the current user $user is different from the recovery folder user: $Get_user, the volume continues to be restored, the volume does not recover and exit the script"
get_version "Recovery Installation" "Do not recover installation" && recovery_mode2="$branch"
fi
echoRgb "Whether to restore multimedia data\n -Restore the volume up, do not restore the volume down" "2"
get_version "Recover media data" "Skip media data recovery" && media_recovery="$branch"
echoRgb "Whether to flash the Magisk module\n -Flash the volume up, do not flash the volume down" "2"
get_version "Flash the module" "Skip flashing the module" && modules_recovery="$branch"
echoRgb "Ignore recovery if there is a process\n -Ignore when volume is up, restore when volume is down" "2"
get_version "Ignore" "Restore" && Background_apps_ignore="$branch" ;;
2)
[[ $recovery_mode = "" ]] && {
Enter_options "Select application recovery mode\n -Enter 1 to restore only uninstalled, 0 to restore all" "Restore only uninstalled" "Restore all" && isBoolean "$parameter" "recovery_mode" && recovery_mode="$nsx"
} || {
isBoolean "$recovery_mode" "recovery_mode" && recovery_mode="$nsx"
}
[[ $setDisplayPowerMode = "" ]] && {
Enter_options "Turn off the screen when the application is restored\n -Enter 1 to turn off, 0 not to turn off" "Turn off" "Do not turn off" && isBoolean "$parameter" "setDisplayPowerMode" && setDisplayPowerMode="$nsx"
} || {
isBoolean "$recovery_mode" "recovery_mode" && recovery_mode="$nsx"
}
Get_user="$(echo "$MODDIR" | rev | cut -d '/' -f1 | cut -d '_' -f1 | rev | egrep -o '[0-9]+')"
[[ $Get_user != $user ]] && {
[[ $recovery_mode2 = "" ]] && {
Enter_options "Detect that the current user $user is different from the recovery folder user: $Get_user. Enter 1 to continue recovery, 0 not to recover and exit the script" "Recovery installation" "Exit script" && isBoolean "$parameter" "recovery_mode2" && recovery_mode2="$nsx"
} || {
isBoolean "$recovery_mode2" "recovery_mode2" && recovery_mode2="$nsx"
}
}
[[ $media_recovery = "" ]] && {
Enter_options "Whether to restore multimedia\n - Enter 1 to restore only, 0 not to restore" "Restore" "Do not restore" && isBoolean "$parameter" "media_recovery" && media_recovery="$nsx"
} || {
isBoolean "$media_recovery" "media_recovery" && media_recovery="$nsx"
}
[[ $modules_recovery = "" ]] && {
Enter_options "Whether to flash Magisk module\n - Enter 1 to flash 0 not to flash" "Flash module" "Skip flash module" && isBoolean "$parameter" "modules_recovery" && modules_recovery="$nsx"
} || {
isBoolean "$modules_recovery" "modules_recovery" && modules_recovery="$nsx"
}
[[ $Background_apps_ignore = "" ]] && {
Enter_options "Ignore recovery if there is a process\n - Enter 1 to not recover, 0 to recover" "Ignore" "Recover" && isBoolean "$parameter" "Background_apps_ignore" && Background_apps_ignore="$nsx"
} || {
isBoolean "$Background_apps_ignore" "Background_apps_ignore" && Background_apps_ignore="$nsx"
} ;;
*) echoRgb "$conf_path Lo=$Lo is filled in incorrectly, the correct value is 0 1 2" "0" && exit 2 ;;
esac
[[ $recovery_mode2 = false ]] && exit 2
if [[ $recovery_mode = true ]]; then
echoRgb "Getting the application that is not installed"
Apk_info="$(pm list packages -u --user "$user" | cut -f2 -d ':' | egrep -v 'ice.message|com.topjohnwu.magisk' | sort -u)"
if [[ $Apk_info != "" ]]; then
[[ $Apk_info = *"Failure calling service package"* ]] && Apk_info="$(appinfo "user|system" "pkgName" 2>/dev/null | egrep -v 'ice.message|com.topjohnwu.magisk' | sort -u)"
        	else
        	    Apk_info="$(appinfo "user|system" "pkgName" 2>/dev/null | egrep -v 'ice.message|com.topjohnwu.magisk' | sort -u)"
        	fi
        	[[ $Apk_info = "" ]] && echoRgb "Apk_info variable is empty" "0" && exit
    		while read -r; do
                if [[ $(echo "$REPLY" | sed 's/^[ \t]*//') != \#* ]]; then
                    app=($REPLY $REPLY)
            		[[ ${app[1]} != "" && ${app[2]} != "" ]] && {
        	        [[ $(echo "$Apk_info" | egrep -o "${app[1]}") = "" ]] && Tmplist="$Tmplist\n$REPLY"
}
fi
done < "$txt"
r="$(echo "$Tmplist" | awk 'NF != 0 { count++ } END { print count }')"
if [[ $r != "" ]]; then
echoRgb "Getting completed. Estimated installation of $r applications"
txt="$Tmplist"
case $Lo in
0|1)
echoRgb "Uninstalled application list\n$txt\nConfirm that it is correct. Use the volume up to continue to restore. Exit the script when the volume is down" "1"
get_version "Restore installation" "Exit script" ;;
2)
Enter_options "Uninstalled application list\n$txt\n-Enter 1 to exit the script, 0 to restore" "Exit script" "Restore installation" isBoolean "$parameter" "branch" && branch="$nsx" ;;
esac
[[ $branch = false ]] && exit
else
echoRgb "Getting completed but the applications in the backup have been installed.... Exiting the script" "0" && exit 0
fi
fi
DX="Batch restore"
else
i=1
r=1
Backup_folder="$MODDIR"
app_details="$Backup_folder/app_details.json"
if [[ ! -f $app_details ]]; then
echoRgb "$app_details is missing, unable to get the package name" "0" && exit 1
else
ChineseName="$(jq -r 'to_entries[] | select(.key != null).key' "$app_details" | head -n 1)"
PackageName="$(jq -r '.[] | select(.PackageName != null).PackageName' "$app_details")"
apk_version="$(jq -r '.[] | select(.apk_version != null).apk_version' "$app_details")"
fi
name1="$ChineseName"
name1="${name1:="${Backup_folder##*/}"}"
[[ $name1 = "" ]] && echoRgb "Application name acquisition failed" "0" && exit 2
name2="$PackageName"
[[ $name2 = "" ]] && echoRgb "Package name acquisition failed" "0" && exit 2
DX="Single recovery"
[[ $Background_apps_ignore != "" ]] && isBoolean "$Background_apps_ignore" "Background_apps_ignore" && Background_apps_ignore="$nsx" || {
echoRgb "Ignore recovery of existing processes\n - ignore when volume is up, recover when volume is down" "2"
get_version "ignore" "recover" && Background_apps_ignore="$branch"
}
fi
#Start looping the data in $txt for recovery
#Record start time
starttime1="$(date -u "+%s")"
TIME="$starttime1"
Set_screen_pause_seconds on
en=118
echo "$script">"$TMPDIR/scriptTMP"
notification "105" "Start recovery app"
{
while [[ $i -le $r ]]; do
[[ $en -ge 229 ]] && en=118
if [[ $operate = Restore ]]; then
echoRgb "Restore the $i/$rth application. $((r - i)) left" "3"
notification "105" "Restore the $i/$rth application. $((r - i)) left
Restore $name1 \"$name2\""
if [[ ! -f $txt ]]; then
[[ $(echo "$txt") != "" ]] && {
name1="$(echo "$txt" | sed -e '/^$/d' | sed -n "${i}p" | awk '{print $1}')"
name2="$(echo "$txt" | sed -e '/^$/d' | sed -n "${i}p" | awk '{print $2}')"
}
else
name1="$(egrep -v '#|#' "$txt" 2>/dev/null | sed -e '/^$/d' | sed -n "${i}p" | awk '{print $1}')"
		        name2="$(egrep -v '#|#' "$txt" 2>/dev/null | sed -e '/^$/d' | sed -n "${i}p" | awk '{print $2}')"
		    fi
		    unset No_backupdata apk_version Permissions
		    if [[ $name1 = *! || $name1 = *! ]]; then
name1="$(echo "$name1" | sed 's/!//g ; s/！//g')"
echoRgb "Skip restoring all data of $name1" "0"
No_backupdata=1
fi
Backup_folder="$MODDIR/$name1"
if [[ -f "$Backup_folder/app_details.json" ]]; then
app_details="$Backup_folder/app_details.json"
apk_version="$(jq -r '.[] | select(.apk_version != null).apk_version' "$app_details")"
else
echoRgb "$Backup_folder/app_details.json does not exist" "0"
fi
[[ $name2 = "" ]] && echoRgb "Failed to obtain the application package name" "0" && exit 1
fi
if [[ -d $Backup_folder ]]; then
echoRgb "Restore $name1 ($name2)" "2"
Background_application_list
restore="true"
[[ $Backstage != "" && $(echo "$Backstage" | egrep -w "^$name2$") != "" ]] && echoRgb "$name1 exists in the background. Ignore restore" "0" && restore="false"
[[ $restore = true ]] && {
starttime2="$(date -u "+%s")"
if [[ $(pm path --user "$user" "$name2" 2>/dev/null) = "" ]]; then
installapk
else
[[ $apk_version -gt $(pm list packages --show-versioncode --user "$user" "$name2" 2>/dev/null | cut -f3 -d ':' | head -n 1) ]] && installapk && [[ $? = 0 ]] && echoRgb "Version upgrade$(pm list packages --show-versioncode --user "$user" "$name2" 2>/dev/null | cut -f3 -d ':' | head -n 1)>$apk_version" "1"
			fi
			if [[ $(pm path --user "$user" "$name2" 2>/dev/null) != "" ]]; then
				if [[ $No_backupdata = "" ]]; then
				    [[ $name2 != *mt* ]] && {
					kill_app
					find "$Backup_folder" -maxdepth 1 ! -name "apk.*" -name "*.tar*" -type f 2>/dev/null | sort | while read; do
						Release_data "$REPLY"
					done
					unset G					restore_permissions
					Ssaid="$(jq -r '.[] | select(.Ssaid != null).Ssaid' "$app_details")"
					if [[ $Ssaid != "" ]]; then
SSAID_Package="$(echo "$name1 $name2 $Ssaid")"
SSAID_Package2="$(echo "$SSAID_Package\n$SSAID_Package2")"
unset Ssaid
fi
}
fi
else
[[ $No_backupdata = "" ]]&& echoRgb "$name1 is not installed and data cannot be restored" "0"
fi
endtime 2 "$name1 restore" "2" && echoRgb "Complete $((i * 100 / r))%" "3"
rgb_d="$rgb_a"
rgb_a=188
echoRgb "_________________$(endtime 1 "already")___________________"
rgb_a="$rgb_d"
}
else
echoRgb "$Backup_folder folder is lost and cannot be restored" "0"
fi
if [[ $i = $r && $operate != Restore2 ]]; then
endtime 1 "Apply restore" "2"
[[ $SSAID_Package2 != "" ]] && {
echoRgb "Start restoring saaid" "0"
echo "$SSAID_Package2" | while read; do
Ssaid="$(echo "$REPLY" | awk '{print $3}')"
name1="$(echo "$REPLY" | awk '{print $1}')"
name2="$(echo "$REPLY" | awk '{print $2}')"
set_ssaid "$name2" "$Ssaid"
if [[ $(get_ssaid "$name2") = $Ssaid ]]; then
echoRgb "$name1 SSAID recovery successful" "1"
SSAID_Package0="$(echo "$name1 \"$name2\"")"
SSAID_Package1="$(echo "$SSAID_Package0\n$SSAID_Package1")"
else
echoRgb "$name1 SSAID recovery failed" "0"
SSAID_Package3="$(echo "$name1 \"$name2\"")"
SSAID_Package4="$(echo "$SSAID_Package3\n$SSAID_Package4")"
fi
unset Ssaid
done
echoRgb "After SSAID recovery, you must restart the computer to apply it, otherwise the application will crash. If you do not apply ssaid recovery, you do not need to restart" "0"
notification "107" "After SSAID is restored, you must restart the computer to apply it, otherwise the application will crash. If there is no application recovery, there is no need to restart."
}
notification "105" "App recovery completed $(endtime 1 "App recovery" "2")"
if [[ $media_recovery = true ]]; then
starttime1="$(date -u "+%s")"
app_details="$Backup_folder2/app_details.json"
txt="$MODDIR/mediaList.txt"
sort -u "$txt" -o "$txt" 2>/dev/null
A=1
B="$(egrep -v '#|＃' "$txt" 2>/dev/null | awk 'NF != 0 { count++ } END { print count }')"
[[ $B = "" ]] && echoRgb "The name of the mediaList.txt compressed package is empty or commented\n - Please execute\"Regenerate application list.sh\" to obtain the list and then restore" "0" && B=0
notification "106" "Media restore starts"
while [[ $A -le $B ]]; do
name1="$(egrep -v '#|＃' "$txt" 2>/dev/null | sed -e '/^$/d' | sed -n "${A}p" | awk '{print $1}')"
starttime2="$(date -u "+%s")"
echoRgb "Restore the $A/$B compressed package. The remaining $((B - A))" "3"
Release_data "$Backup_folder2/$name1"
endtime 2 "$FILE_NAME2 restore" "2" && echoRgb "Complete $((A * 100 / B))%" "3" && echoRgb "____________________________________" && let A++
done
endtime 1 "Custom recovery" "2"
notification "106" "Media recovery completed $(endtime 1 "Media recovery" "2")"
fi
if [[ $modules_recovery = true ]]; then
A=1
B="$(find "$Backup_folder3" -maxdepth 1 -name "*.zip*" -type f 2>/dev/null | wc -l)"
starttime1="$(date -u "+%s")"
notification "108" "Module recovery started"
find "$Backup_folder3" -maxdepth 1 -name "*.zip*" -type f 2>/dev/null | while read; do
starttime2="$(date -u "+%s")"
echoRgb "Flashing $A/$B modules, $((B - A)) remaining" "3"
echoRgb "Flashing ${REPLY##*/}" "2"
magisk --install-module "$REPLY"
endtime 2 "Flashing ${REPLY##*/}" "2" && echoRgb "Complete $((A * 100 / B))%" "3" && echoRgb "____________________________________" && let A++
done
endtime 1 "Flashing modules" "2"
notification "108" "Module recovery completed $(endtime 1 "Module recovery" "2")"

fi
fi
let i++ en++ nskg++
done
Set_screen_pause_seconds off
[[ $user != 0 ]] && am stop-user "$user"
starttime1="$TIME"
echoRgb "$DX completed" && endtime 1 "$DX start to end"
notification "109" "Restore completed $(endtime 1 "$DX start to end")"
rm -rf "$TMPDIR"/*
} &
wait && exit
;;
Restore3)
kill_Serve
self_test
case $Lo in
0|1)
echoRgb "Clicked wrong? This is the script to restore the custom folder. If you want to restore the application, then you clicked wrong\n - Volume up to continue restoring the custom folder, volume down to leave the script" "2"
echoRgb "If you regret to terminate the script, please leave this script as soon as possible and click the termination script.sh, otherwise the script will continue to run until the end" "0"
get_version "Restore custom folders" "Exit script" && [[ $branch = false ]] && exit 0 ;;
2)
Enter_options "Clicked wrong? This is the script to restore custom folders. If you want to restore the application, then you clicked wrong\n - Enter 1 to continue restoring custom folders, enter 0 to exit the script" "Restore" "Exit script" && isBoolean "$parameter" "branch" && branch="$nsx" && [[ $branch = false ]] && exit 0 ;;
esac
mediaDir="$MODDIR/Media"
[[ -f "$mediaDir/app_details.json" ]] && app_details="$mediaDir/app_details.json"
Backup_folder2="$mediaDir"
[[ ! -d $mediaDir ]] && echoRgb "Media folder does not exist" "0" && exit 2
txt="$MODDIR/mediaList.txt"
[[ ! -f $txt ]] && echoRgb "Please execute\"Regenerate application list.sh\"Get the media list and restore it" "0" && exit 2
sort -u "$txt" -o "$txt" 2>/dev/null
#Record start time
starttime1="$(date -u "+%s")"
echo_log() {
if [[ $? = 0 ]]; then
echoRgb "$1 success" "1" && result=0
else
echoRgb "$1 failed to restore, died" "0" && result=1
fi
}
starttime1="$(date -u "+%s")"
A=1
B="$(egrep -v '#|＃' "$txt" 2>/dev/null | awk 'NF != 0 { count++ } END { print count }')"
Set_screen_pause_seconds on
[[ $B = "" ]] && echoRgb "The name of the mediaList.txt compressed package is empty or commented\n - Please execute\"Regenerate application list.sh\" to obtain the list and then restore" "0" && exit 1
echo "$script">"$TMPDIR/scriptTMP"
notification "108" "Media recovery starts"
{
while [[ $A -le $B ]]; do
name1="$(egrep -v '#|＃' "$txt" 2>/dev/null | sed -e '/^$/d' | sed -n "${A}p" | awk '{print $1}')"
starttime2="$(date -u "+%s")"
echoRgb "Restore the $A/$B compressed package. $((B - A)) left" "3"
Release_data "$mediaDir/$name1"
endtime 2 "Restore $FILE_NAME2" "2" && echoRgb "Complete $((A * 100 / B))%" "3" && echoRgb "____________________________________" && let A++
done
Set_screen_pause_seconds off
endtime 1 "Restore completed"
notification "108" "Media restore completed $(endtime 1 "Media restore")"
rm -rf "$TMPDIR/scriptTMP"
} &
;;
Getlist)
case $MODDIR in
/storage/emulated/0/Android/* | /data/media/0/Android/* | /sdcard/Android/*) echoRgb "Do not generate a list in $MODDIR" "0" && exit 2 ;;
esac
#Verify that the options are correct
isBoolean "$debug_list" "debug_list" && debug_list="$nsx"
case $Lo in
0)
[[ $blacklist_mode != "" ]] && isBoolean "$blacklist_mode" "blacklist_mode" && blacklist_mode="$nsx" || {
echoRgb "Select blacklist mode\n - Do not output when volume is high, output application list when volume is low" "2"
get_version "Do not output" "Output application list" && blacklist_mode="$branch"
}
[[ $recovery_flash != "" ]] && isBoolean "$recovery_flash" "recovery_flash" && recovery_flash="$nsx" || {
echoRgb "Output the card flash package for recovery rescue? \n - Output when volume is up, no output when volume is down" "2"
get_version "Output" "No output" && recovery_flash="$branch"
} ;;
1)
if [[ $(echo "$blacklist" | egrep -v '#|＃' | wc -l) -gt 0 ]]; then
[[ $blacklist_mode = "" ]] && {
echoRgb "Select blacklist mode\n - No output when volume is up, output application list when volume is down" "2"
get_version "No output" "Output application list" && blacklist_mode="$branch"
} || isBoolean "$blacklist_mode" "blacklist_mode" && blacklist_mode="$nsx"
fi
[[ $recovery_flash = "" ]] && {
echoRgb "Output the card flash package for recovery rescue?\n - Output when volume is up, no output when volume is down" "2"
get_version "Output" "No output" && recovery_flash="$branch"
} || isBoolean "$recovery_flash" "recovery_flash" && recovery_flash="$nsx" ;;
2)
[[ $blacklist_mode = "" ]] && {
Enter_options "Select blacklist mode. Input 1 to not output, input 0 to output application list" "No output" "Output application list" && isBoolean "$parameter" "blacklist_mode" && blacklist_mode="$nsx"
} || {
isBoolean "$blacklist_mode" "blacklist_mode" && blacklist_mode="$nsx"
}
[[ $recovery_flash = "" ]] && {
Enter_options "Fill in 1 to output the card flash package for recovery rescue, fill in 0 not to output" "Output" "Not output" && isBoolean "$parameter" "recovery_flash" && recovery_flash="$nsx"
} || {
isBoolean "$recovery_flash" "recovery_flash" && recovery_flash="$nsx"
} ;;
*) echoRgb "$conf_path Lo=$Lo fill in error, correct value 0 1 2" "0" && exit 2 ;;
esac
txtpath="$MODDIR"
[[ $debug_list = true ]] && txtpath="${txtpath/'/storage/emulated/'/'/data/media/'}"
nametxt="$txtpath/appList.txt"
[[ ! -f $nametxt ]] && echo '#Applications that do not need to be backed up, please use #comment at the beginning. For example: #Cool Security com.coolapk.market (ignore installation packages and data)\n#Applications that do not need to back up data, please use !comment at the beginning. For example: !Cool Security com.coolapk.market (ignore only data)' >"$nametxt"
echoRgb "Do not close the script, wait for the prompt to end"
rgb_a=118
starttime1="$(date -u "+%s")"
echoRgb "Tip! The script will block pre-installed applications by default. If you need to back up, please add a pre-installed application whitelist" "0"
Apk_info="$(appinfo "system|user|xposed" "label|pkgName|flag" | egrep -v 'ice.message|com.topjohnwu.magisk' | sort -u)"
xposed_name="$(echo "$Apk_info" | awk '$3 == "xposed" {print $2}')"
TARGET_PACKAGES="$(echo "$system" | paste -sd'|' - | sed 's/^|//')"
Pre_installed_apps="$(echo "$Apk_info" | awk '$3 == "system" {print $1, $2}' | egrep -w "$TARGET_PACKAGES")"
Apk_info="$(echo "$(echo "$Apk_info" | awk '$3 != "system" {print $1, $2}')\n$Pre_installed_apps")"
[[ $Apk_info = "" ]] && {
echoRgb "appinfo output failed, please take a screenshot and report to the author" "0"
exit 2 ; } || Apk_info2="$(echo "$Apk_info" | awk '{print $2}')"
Apk_Quantity="$(echo "$Apk_info" | wc -l)"
LR="1"
echoRgb "List third-party applications......." "2"
i="0"
rc="0"
rd="0"
Q="0"
rb="0"
Output_list() {
if [[ $(cat "$nametxt" | cut -f2 -d ' ' | egrep -w "^${app_1[1]}$") != ${app_1[1]} ]]; then
[[ $REPLY2 = "" ]] && add_entry "${app_1[2]}" "${app_1[1]}" "$(cat "$nametxt" | grep -w "${app_1[2]}")" || add_entry "${app_1[2]}" "${app_1[1]}" "$REPLY2"
case ${app_1[1]} in
*oneplus* | *miui* | *xiaomi* | *oppo* | *flyme* | *meizu* | com.android.soundrecorder | com.mfashiongallery.emag | com.mi.health | *coloros*)
if [[ $(echo "$xposed_name" | egrep -w "${app_1[1]}$") = ${app_1[1]} ]]; then
echoRgb "$app_name is added to the Xposed module" "0"
if [[ $REPLY2 = "" ]]; then
REPLY2="$REPLY" && [[ $tmp = "" ]] && tmp="1"
else
					        REPLY2="$REPLY2\n$REPLY" && [[ $tmp = "" ]] && tmp="1"
					    fi
					    let i++ rd++
				    else
					    if [[ $(echo "$whitelist" | egrep -w "^${app_1[1]}$") = ${app_1[1]} ]]; then
					        if [[ $REPLY2 = "" ]]; then
					            REPLY2="$REPLY" && [[ $tmp = "" ]] && tmp="1"
					        else
					            REPLY2="$REPLY2\n$REPLY" && [[ $tmp = "" ]] && tmp="1"
					        fi
						    echoRgb "$app_name ${app_1[1]}($rgb_a)"
						    let i++
					    else
						    echoRgb "$app_name pre-installed application ignore output" "0"						    if [[ $REPLY2 = "" ]]; then
    						    REPLY2="#$REPLY" && [[ $tmp = "" ]] && tmp="1"
						    else
						        REPLY2="$REPLY2\n#$REPLY" && [[ $tmp = "" ]] && tmp="1"
						    fi
						    let rc++
					    fi
				    fi
				    ;;
			    *)
				    if [[ $REPLY2 = "" ]]; then
					    REPLY2="$REPLY" && [[ $tmp = "" ]] && tmp="1"
					else
					    REPLY2="$REPLY2\n$REPLY" && [[ $tmp = "" ]] && tmp="1"
					fi
					if [[ $(echo "$xposed_name" | egrep -w "${app_1[1]}$") = ${app_1[1]} ]]; then
			            echoRgb "Xposed: $app_name ${app_1[1]}($rgb_a)"
			            let rd++
			        else
				        echoRgb "$app_name ${app_1[1]}($rgb_a)"
				    fi
				    let i++
				    ;;
			esac
		else
	        let Q++
        fi
    }
    [[ $(echo "$blacklist" | egrep -v '#|#') != "" ]] && NZK=1
	echo "$Apk_info" | sed 's/[\/:()\[\]\-!]//g' | while read; do
		[[ $rgb_a -ge 229 ]] && rgb_a=118
		app_1=($REPLY $REPLY)
		if [[ $NZK = 1 ]]; then
    		if [[ $(echo "$blacklist" | egrep -w "^${app_1[1]}$") != ${app_1[1]} ]]; then
Output_list
else
if [[ $blacklist_mode = false ]]; then
Output_list
let rb++
else
echoRgb "${app_1[2]} blacklist application not output" "0"
let rb++
fi
fi
else
Output_list
fi
if [[ $LR = $Apk_Quantity ]]; then
echo "$REPLY2">>"$nametxt"
if [[ $(cat "$nametxt" | wc -l | awk '{print $1-2}') -lt $i ]]; then
rm -rf "$nametxt"
echoRgb "\n - Output abnormality Please change debug_list=\"0\" in $conf_path to 1 or re-execute this script" "0"
exit
fi
echoRgb "The pre-installed applications have been exported to appList.txt and commented #. If you need to back up, remove #" "0"
[[ $tmp != "" ]] && echoRgb "\n -Third-party apk quantity=\"$Apk_Quantity\"\n -Filtered=\"$rc\"\n -xposed=\"$rd\"\n -Blacklist application=\"$rb\"\n -Existing in the list=\"$Q\"\n -Output=\"$i\""
fi
let rgb_a++ LR++
done
if [[ -f $nametxt ]]; then
rm -rf "$TMPDIR"/*
while read -r ; do
if [[ $(echo "$REPLY" | sed -E 's/^[ \t]*//; /^[ \t]*[#＃!]/d') != "" ]]; then
app=($REPLY $REPLY)
if [[ ${app[1]} != "" && ${app[2]} != "" ]]; then
if [[ $(echo "$Apk_info2" | egrep -o "${app[1]}") != "" ]]; then
[[ $Tmplist = "" ]] && Tmplist='#Applications that do not need to be backed up should be used at the beginning#Comment For example: #Cool Security com.coolapk.market (ignore installation package and data\n#Applications that do not need to be backed up should be used at the beginning!Comment For example: !Cool Security com.coolapk.market (only ignore data)'
Tmplist="$Tmplist\n$REPLY"
[[ $recovery_flash = true ]] && {
apk_path="$(pm path --user "$user" "${app[1]}" 2>/dev/null | cut -f2 -d ':')"
apk_path2="$(echo "$apk_path" | head -1)"
apk_path2="${apk_path2%/*}"
echo "${app[2]} ${app[1]} $apk_path2" >>"$TMPDIR/appList.txt"
}
else
echoRgb "$REPLY does not exist on the system, delete from the list" "0"
fi
fi
else
Tmplist="$Tmplist\n$REPLY"
fi
done < "$nametxt"
[[ $Tmplist != "" ]] && echo "$Tmplist" | sed -e '/^$/d' | sort>"$nametxt"
if [[ $recovery_flash = true ]]; then
if [[ -f $tools_path/update-binary && -f $TMPDIR/appList.txt ]]; then
echoRgb "Output the backup card flash package for recovery" ; rm -rf "$MODDIR/recovery card flash backup.zip"
touch_shell "Restore" "$TMPDIR/Restore backup.sh"
cp -r "$MODDIR/Terminate script.sh" "$TMPDIR/Terminate script.sh"
touch_shell "dumpname" "$TMPDIR/Regenerate application list.sh"
touch_shell "convert" "$TMPDIR/Convert folder name.sh"
touch_shell "check_file" "$TMPDIR/compressed file integrity check.sh"
touch_shell "Restore2" "$TMPDIR/recover.sh"
touch_shell "Restore3" "$TMPDIR/recover custom folder.sh"
update_Restore_settings_conf>"$TMPDIR/restore_settings.conf"
mkdir -p "$TMPDIR/META-INF/com/google/android" && cp "$tools_path/update-binary" "$TMPDIR/META-INF/com/google/android"
tar -cpf - -C "${tools_path%/*}" "${tools_path##*/}" | tar --delete "tools/zip" | tar --recursive-unlink -xmpf - -C "$TMPDIR/"
(cd "$TMPDIR" && zip -r "recovery card brush backup.zip" * -x 'scriptTMP')
echo_log "Package card brush package"
[[ $result = 0 ]] && (mv "$TMPDIR/recovery card brush backup.zip" "$MODDIR" && rm -rf "$TMPDIR"/* ; echoRgb "Output: $MODDIR/recovery card brush backup.zip" "2")
else
[[ ! -f $tools_path/update-binaryechoRgb ]] && echoRgb "update-binary card brush script missing" "0" || [[ ! -f $TMPDIR/appList.txt ]] && echoRgb "$TMPDIR/appList.txt does not exist" "0"
fi
fi
fi
wait
endtime 1
echoRgb "Output package name ends, please check $nametxt"
;;
backup_media)
kill_Serve
self_test
backup_path
echoRgb "If you regret and want to terminate the script, please leave this script as soon as possible and click the termination script.sh, otherwise the script will continue to execute until the end" "0"
A=1
B="$(echo "$Custom_path" | egrep -v '#|＃' | awk 'NF != 0 { count++ } END { print count }')"
if [[ $B != "" ]]; then
starttime1="$(date -u "+%s")"
Backup_folder="$Backup/Media"
[[ ! -d $Backup_folder ]] && mkdir -p "$Backup_folder"
[[ ! -f $Backup/Restore custom folder.sh ]] && touch_shell "Restore3" "$Backup/Restore custom folder.sh"
[[ ! -f $Backup/Regenerate application list.sh ]] && touch_shell "dumpname" "$Backup/Regenerate application list.sh"
[[ ! -f $Backup/Convert folder name.sh ]] && touch_shell "convert" "$Backup/Convert folder name.sh"
[[ ! -f $Backup/Compressed file integrity check.sh ]] && touch_shell "check_file" "$Backup/Compressed file integrity check.sh"
[[ ! -d $Backup/tools ]] && cp -r "$tools_path" "$Backup"
[[ ! -f $Backup/restore_settings.conf ]] && update_Restore_settings_conf>"$Backup/restore_settings.conf"
app_details="$Backup_folder/app_details.json"
[[ ! -f $app_details ]] && echo "{\n}">"$app_details"
filesize="$(find "$Backup_folder" -type f -printf "%s\n" 2>/dev/null | awk '{s+=$1} END {print s}')"
mediatxt="$Backup/mediaList.txt"
[[ ! -f $mediatxt ]] && echo "#Folders that do not need to be restored, please use #comments at the beginning, for example: #Download" > "$mediatxt"
echo "$script">"$TMPDIR/scriptTMP"
Set_screen_pause_seconds on
notification "109" "Media backup starts"
{
echo "$Custom_path" | sed -e '/^#/d; /^$/d; s/\/$//' | while read; do
echoRgb "Backup folder $A/$B, $((B - A)) remaining" "3"
starttime2="$(date -u "+%s")" 
if [[ ${REPLY##*/} = adb ]]; then
if [[ $ksu != ksu ]]; then
echoRgb "Magisk adb"
Backup_data "${REPLY##*/}" "$REPLY"
else
echoRgb "KernelSU adb does not support backup" "0"
Set_back_0
fi
else
Backup_data "${REPLY##*/}" "$REPLY"
fi
endtime 2 "${REPLY##*/} backup" "1"
echoRgb "Complete $((A * 100 / B))% $hx$(echo "$Occupation_status" | awk 'END{print "Remaining: "$1" Usage: "$2}')" "2" && echoRgb "____________________________________" && let A++
done
} &
wait
Calculate_size "$Backup_folder"
Set_screen_pause_seconds off
endtime 1 "Custom backup"
notification "109" "Media backup completed $(endtime 1 "Custom backup")"
rm -rf "$TMPDIR/scriptTMP"
else
echoRgb "Custom path is empty, cannot backup" "0"
fi
;;
Device_List)
    URL="https://raw.githubusercontent.com/KHwang9883/MobileModels/refs/heads/master/brands"
    rm -rf "$tools_path/Device_List"
    for i in $(echo "xiaomi\nxiaomi_en\nsamsung\nsamsung_global\nasus\nBlack_Shark\nBlack_Shark_en\ngoogle\nLenovo\nMEIZU\nMEIZU_en \nMotorola\nNokia\nnothing\nnubia\nOnePlus\nOnePlus_en\nSony\nrealme\nrealme_en\nvivo\nvivo_en\noppo\noppo_en"); do
        echoRgb "Get brand $i"
        case $i in
        xiaomi) Brand_URL="$URL/xiaomi.md" ;;
        xiaomi_en) Brand_URL="$URL/xiaomi_en.md" ;;
        samsung) Brand_URL="$URL/samsung_cn.md" ;;
        samsung_global) Brand_URL="$URL/samsung_global_en.md" ;;
        asus) Brand_URL="$URL/asus.md" ;;
        Black_Shark) Brand_URL="$URL/blackshark.md" ;;
        Black_Shark_en) Brand_URL="$URL/blackshark_en.md" ;;
        google) Brand_URL="$URL/google.md" ;;
        Lenovo) Brand_URL="$URL/lenovo.md" ;;
        MEIZU) Brand_URL="$URL/meizu.md" ;;
        MEIZU_en) Brand_URL="$URL/meizu_en.md" ;;
        Motorola) Brand_URL="$URL/motorola.md" ;;
        Nokia) Brand_URL="$URL/nokia.md" ;;
        nothing) Brand_URL="$URL/nothing.md" ;;
        nubia) Brand_URL="$URL/nubia.md" ;;
        OnePlus) Brand_URL="$URL/oneplus.md" ;;
        OnePlus_en) Brand_URL="$URL/oneplus_en.md" ;;
        Sony) Brand_URL="$URL/sony_cn.md" ;;
        realme) Brand_URL="$URL/realme_cn.md" ;;
        realme_en) Brand_URL="$URL/realme_global_en.md" ;;
        vivo) Brand_URL="$URL/vivo_cn.md" ;;
        vivo_en) Brand_URL="$URL/vivo_global_en.md" ;;
        oppo) Brand_URL="$URL/oppo_cn.md" ;;
        oppo_en) Brand_URL="$URL/oppo_global_en.md" ;;
        esac
        if [[ ! -e $tools_path/Device_List ]]; then
            down "$Brand_URL" | grep -oE '[^`]+`:[^`]*' | sed -E 's/: /:/g' | sed -E 's/`([^`]+)`:(.*)/"\1" "\2"/'>"$tools_path/Device_List"
        else
            down "$Brand_URL" | grep -oE '`[^`]+`:[^`]*' | sed -E 's/: /:/g' | sed -E 's/`([^`]+)`:(.*)/"\1" "\2"/' | while read ; do
                unset model
                model="$(echo "$REPLY" | awk -F'"' '{print $2}')"
                if [[ $(egrep -w "$model" "$tools_path/Device_List" | awk -F'"' '{print $2}') != $model ]]; then
                    echo "$REPLY">>"$tools_path/Device_List"
                else
                    echo "$(egrep -w "$model" "$tools_path/Device_List" | awk -F'"' '{print $2}') = $model"
                fi
            done
        fi
    done
    if [[ -e $tools_path/Device_List ]]; then
        if [[ $(ls -l "$tools_path/Device_List" | awk '{print $5}') -gt 1 ]]; then
[[ $shell_language = zh-TW ]] && ts <"$tools_path/Device_List">temp && cp temp "$tools_path/Device_List" && rm temp
echoRgb "Downloaded model list in $tools_path/Device_List"
else
echoRgb "Download model failed"
fi
else
echoRgb "Download model failed"
fi ;;
esac