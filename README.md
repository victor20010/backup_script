# Backup_script data backup script
[![Stars](https://img.shields.io/github/stars/YAWAsau/backup_script?label=stars)](https://github.com/YAWAsau)
[![Download](https://img.shields.io/github/downloads/YAWAsau/backup_script/total)](https://github.com/YAWAsau/backup_script/releases)
[![Release](https://img.shields.io/github/v/release/YAWAsau/backup_scrip t?label=release)](https://github.com/YAWAsau/backup_script/releases/latest)
[![License](https://img.shields.io/github/license/YAWAsau/backup_script?label=License)](https://choosealicense.com/licenses/gpl-3.0)
[![Channel](https://img.shields.io/badge/Follow-Telegram-blue.svg?logo=telegram)](https://t.me/yawasau_script)

## Overview

This script is created to enable users to **backup/restore** application data more completely.
Supported devices must meet the following conditions: `Android 8+`+`arm64`.

Since I am Taiwanese, the version I released is the Traditional Chinese version
(CN system will automatically translate its own script into Simplified Chinese)

## Advantages

- Complete data: After changing the system, all the original data will be retained, without the need to re-login or download additional data packages.

- Support backup of SSAID, which can perfectly backup LINE

- Support backup of application permissions, which can backup runtime permissions and ops permissions

- Easy to operate: You can backup the complete application data in a few simple steps!

- Few restrictions: No restrictions on models, and can cross Android versions.

- Powerful functions: Can backup and restore `split apk`.

- Multiple algorithms: Currently supported compression algorithms are `tar (default)`

- `zstd`.

- Fast speed: Even with the `zstd` compression algorithm, the speed is still fast (compared to Swift Backup).
- The script comes with tools integrity verification and compression package verification
## How to use
`Please read the following instructions carefully to reduce unnecessary problems`

##### Recommended tools: [`MT Manager`](https://www.coolapk.com/apk/bin.mt.plus), if you use `Termux`, please do not use `tsu`.

#### !!!All the following operations require ROOT!!! ####

1. First, unzip the downloaded `Data backup script.zip` to any directory, and you can see the following files and a directory: `Generate application list.sh` `backup_settings.conf` `Backup application.sh` `tools` `Backup custom folder.sh` `Terminate script.sh` `Warning! Whether it is backup or recovery, the existence and integrity of tools must be guaranteed, otherwise the script will be invalid or the binary call will fail.`

2. Then execute the `Generate application list.sh` script, and wait for the script output to end, and then wait for the prompt to end. At this time, an `appList.txt` will be generated in the current directory, which is all the third-party applications you currently installed.

3. Now open the generated `appList.txt`, follow the prompts and save it, and you have set up the software that needs to be backed up.

4. Finally, find `backup_settings.conf`, open it, save it according to the prompts, and then open `backup application.sh`. After the backup is completed, a folder named `Backup_compression algorithm name` will be generated in the current directory, which contains your software backup. Save the entire folder to another location, copy it back to the phone after flashing, and directly find `Restore backup.sh` in the folder to restore all the backed-up data. Similarly, there is also an `appList.txt` in it. The usage is the same as step 3. Delete the files that do not need to be restored. In addition, go to the backed-up folder and find the separate application folder. There is a Backup script and restore script that can be used to backup and restore scripts separately.

5. During the script execution, please pay attention to the red word prompts for any errors, and when using the recovery script, pay attention to whether the application is prompted to have ssaid after the recovery is completed. If it is prompted to have ssaid, please restart the application immediately after the recovery to apply ssaid. If you open the application immediately after restoring ssaid, ssaid application will fail, because Android will generate a new ssaid, which will cause the application to be stuck on a white screen or prompt to log in. ssaid is one of the judgments whether the application has changed the environment and device. Keeping it consistent can reduce the methods such as prompting remote login or requiring re-login verification.

##### Additional instructions: How to restore Here are instructions for the files in the recovery folder?

1. Find appList.txt in the recovery folder, open it, edit the list, save and exit

2. Find restore backup.sh, give root and wait for the script to end

3. Regenerate application list.sh can be used to refresh the list in appList.txt. The time to use is when you delete any application backup in the list, or when restore backup.sh prompts a list error

4. Terminate script.sh is used when you suddenly want to terminate the script or when an unexpected operation is performed. Similarly, there is also one for the backup folder. Because the script does not need background features and cannot be terminated by conventional means, a separate script termination is written

# How to update the script?
- There are currently three update methods, as follows
- 1. Manually place the downloaded backup script zip without decompressing it directly in any directory of the script (excluding the tools directory) and execute any script to update. The script will prompt
- 2. When executing any script of this backup, it will connect to the Internet to detect the script version. When updating, it will automatically prompt and download. Just follow the prompts of the script (effective when conf update=1). The script connection is only used to check the update, and there is no illegal operation or formatting machine
- 3. Place the downloaded compressed package without decompressing it directly in /storage/emulated/0/Download. The script will automatically detect the update and follow the prompts
- 4. The script downloaded in the QQ group will be automatically updated without unzipping the script

## About Feedback
- If there is a problem during use, please bring a screenshot and explain the problem in detail, and create [issues](https://github.com/YAWAsau/backup_script/issues).
- Coolapk @[落叶淒涼TEL](http://www.coolapk.com/u/2277637)
- QQ group 976613477
- TG ​​https://t.me/yawasau_script

## Q&A
- Why is there dex in a shell script?
- dex is used to achieve the purpose that is difficult to achieve with scripts. Currently, saaid backup and restore, backup and restore runtime permissions and ops permissions, download and access GitHub api to check script updates, list user application names and package names, and convert traditional Chinese to simplified Chinese are all functions of dex. Thanks to [Android-DataBackup](https://github.com/XayahSuSuSu/Android-DataBackup) by [XayahSuSuSu](https://github.com/XayahSuSuSu)

## FAQ

Q1: What should I do if a large number of batch backup prompts failure?

A1: Exit the script, delete /data/backup_tools, and back up again

Q2: What should I do if a large number of batch restore prompts failure?

A2: Exit the script and follow the same steps as above. If the error still occurs, please create an issue and I will help you troubleshoot it

Q3: Can WeChat/QQ perfectly backup & restore data?

A3: It cannot be guaranteed. Some people say it cannot and some say it can, so there will be a prompt during the backup. It is recommended to use the backup software you trust to back up WeChat/QQ again to prevent the loss of important data

Q4: Why do some applications take a long time to back up? For example, Honor of Kings, PUBG, Genshin Impact, WeChat, QQ.
A4: Because the software data package is backed up for you, for example, the Genshin Impact data package is 9GB+, of course it has been so old that it has cracked, and the same is true for recovery. You still need to unzip the data package

Q5: Is the script backed up completely every time?
A5;When the script is backed up, it will compare the backup size of the last backup. If there is a difference, it will be backed up. Otherwise, it will be ignored to save time.

Backing up the script took me a lot of time and energy. If you think it is useful, you can donate it. XD
.(https://paypal.me/YAWAsau?country.x=TW&locale.x=zh_TW))

## Thanks for the contribution
- 臭批老k([kmou424](https://github.com/kmou424)): Provided some ideas for verification functions
- 削老方([雄氏老方](http://www.coolapk.com/u/665894)): Provided an automatic script update solution
- 胖子老陳(雨季訷年)
- XayahSuSuSu([XayahSuSuSu](https://github.com/XayahSuSuSu)): Provides App support, dex support

`Document editor: Petit-Abba, YuKongA`