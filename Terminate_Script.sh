if [ -f "${0%/*}/tools/tools.sh" ]; then
	MODDIR="${0%/*}"
	operate="kill_script"
	conf_path="${0%/*}/backup_settings.conf"
	. "$MODDIR/tools/tools.sh"
	echoRgb "Waiting for the script to stop, please wait..."
kill_Serve && echoRgb "Script terminated"
exit
else
[[ $(echo "${0%/*}" | grep -o 'bin.mt.plus/temp') != "" ]] && echo "Didn't your mother tell you to unzip the script? You idiot" && exit 2
echo "${0%/*}/tools/tools.sh is missing"
fi
