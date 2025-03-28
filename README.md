# Backup_script Data Backup Script
[![Stars](https://img.shields.io/github/stars/YAWAsau/backup_script?label=stars)](https://github.com/YAWAsau)
[![Download](https://img.shields.io/github/downloads/YAWAsau/backup_script/total)](https://github.com/YAWAsau/backup_script/releases)
[![Release](https://img.shields.io/github/v/release/YAWAsau/backup_script?label=release)](https://github.com/YAWAsau/backup_script/releases/latest)
[![License](https://img.shields.io/github/license/YAWAsau/backup_script?label=License)](https://choosealicense.com/licenses/gpl-3.0)
[![Channel](https://img.shields.io/badge/Follow-Telegram-blue.svg?logo=telegram)](https://t.me/yawasau_script)

## Overview

This script was created to allow users to completely **backup/restore** application data,
supported devices must meet the following conditions: `Android 8+` + `arm64`.

Since I am Taiwanese, the released version is in Traditional Chinese
(CN system will automatically translate the script to Simplified Chinese)

## Advantages

- Complete data: After changing the system, all the original data is retained, no need to log in again or download additional data packages.
- Supports SSAID backup, perfectly backs up LINE
- Supports application permission backup, can backup runtime permissions and ops permissions
- Easy to operate: backup complete application data in just a few steps!
- Few restrictions: no device model restrictions, can cross Android versions.
- Powerful: can backup and restore `split apk`.
- Multiple algorithms: currently supports compression algorithms `tar (default)` and `zstd`.
- Fast: even with the `zstd` compression algorithm, the speed is still fast (compared to Titanium Backup and Swift Backup).
- The script comes with tools integrity verification and compression package verification

## How to use
`Please read the following instructions carefully to reduce unnecessary problems`

##### Recommended tool: [`MT Manager`](https://www.coolapk.com/apk/bin.mt.plus), if using `Termux`, do not use `tsu`.

#### !!! All operations below require ROOT!!! ####

1. First, extract the downloaded `data backup script.zip` to any directory, then you will see the following files and a directory: `Generate Application List.sh` `backup_settings.conf` `Backup Applications.sh` `tools`.

2. Then execute the `Generate Application List.sh` script and wait for the script to finish outputting. After the prompt ends, a `appList.txt` will be generated in the current directory, which lists all your currently installed third-party applications.

3. Now open the generated `appList.txt`, follow the prompts inside to operate, and save. This way you have set up the software that needs to be backed up.

4. Finally, find `backup_settings.conf`, open it and follow the prompts to set and save. Then open `Backup Applications.sh`, wait for the backup to finish, and a resource named `Backup_compression_algorithm` will be generated in the current directory.

5. During the script execution process, please pay attention to any red text prompts for errors, and when using the restore script, pay attention to whether there is a prompt saying that the application has ssaid after the restore ends. If prompted, please restart immediately after the restore.

##### Additional instructions: How to restore the files in the restore folder?

1. Find the `appList.txt` in the restore folder, open, edit the list, save and exit.

2. Find `restore_backup.sh`, grant root, and wait for the script to finish.

3. Re-run `generate_application_list.sh` to refresh the list in `appList.txt`. Use it when you delete any application backup in the list, or when `restore_backup.sh` prompts a list error.

4. Terminate script.sh is used when you suddenly want to terminate the script or for accidental operations. Similarly, the backup folder also has one, because the script does not require background properties and cannot be terminated by conventional means, so another one is written.

# How to update the script?
- There are currently three update methods:
- 1. Manually place the downloaded backup script zip in any directory (excluding the tools directory) without extracting it, and execute any script to update. The script will prompt.
- 2. Any script of this backup will check the script version online when executed, and will prompt and download when there is an update. Follow the script prompts to operate (conf update=1 is effective). The script connects to the internet only to check for updates.
- 3. Place the downloaded zip package in /storage/emulated/0/Download without extracting it. The script will automatically detect and update according to the prompts.
- 4. Scripts downloaded from QQ groups will be automatically detected and updated.

## Feedback
- If you encounter any problems during use, please provide screenshots and a detailed description of the problem, and create [issues](https://github.com/YAWAsau/backup_script/issues).
- Coolapk @[落葉淒涼TEL](http://www.coolapk.com/u/2277637)
- QQ group 976613477
- TG https://t.me/yawasau_script

## Q&A
- Why is there dex in a shell script?
- Dex is used to achieve purposes that are difficult to achieve with scripts. Currently, saaid backup and restore, runtime permission and ops permission backup and restore, downloading and accessing GitHub API to check script updates, listing user application names and package names.

## FAQ

Q1: What should I do if there are many failures in batch backup?
A1: Exit the script, delete /data/backup_tools, and back up again.

Q2: What should I do if there are many failures in batch restore?
A2: Exit the script, follow the same operation as above. If the error persists, create issues and I will help you troubleshoot.

Q3: Can WeChat/QQ be perfectly backed up and restored?
A3: It cannot be guaranteed. Some people say it can't, others say it can, so there will be a prompt during the backup. It is recommended to use a trusted backup software to backup WeChat/QQ again to prevent losing important data.

Q4: Why do some applications take a long time to backup? For example, Honor of Kings, PUBG, Genshin Impact, WeChat, QQ.
A4: Because the data package of the software is also backed up. For example, Genshin Impact's data package is 9GB+, of course, it will take a long time. The same goes for restoration, and it also needs to decompress the data package.

Q5: Is the script a full backup every time?
A5: The script will compare the size of the backup with the last backup. If there is a difference, it will back up, otherwise, it will ignore the backup to save time.

The backup script took me a lot of time and effort. If you find it useful, you can donate XD.
.(https://paypal.me/YAWAsau?country.x=TW&locale.x=zh_TW))

## Acknowledgements
- 臭批老k([kmou424](https://github.com/kmou424)): Provided some and verification function ideas
- 屑老方([雄氏老方](http://www.coolapk.com/u/665894)): Provided automatic update script scheme
- 胖子老陳(雨季騷年)
- XayahSuSuSu([XayahSuSuSu](https://github.com/XayahSuSuSu)): Provided App support, dex support

`Document editing: Petit-Abba, YuKongA`
