#!/bin/sh
#genalyze.sh
#this script gathers some data about your system and pastes them online 
#for other poeple, so that they can halp you with your problem
# this script is perfectly safe if run as normal user, you may need to be root
# to emerge wgetpaste though 

 
PATH="${PATH}:/usr/sbin:/sbin" #this is needed for utils like lspci

WGETPASTE="/usr/bin/wgetpaste" #binary for pasting online
#checking if you have wgetpaste
if [ -f $WGETPASTE ] ; then echo "wgetpaste found, continuing"
else "please emerge wgetpaste (run as root 'emerge wgetpaste') and then run this script again"; exit 1;
fi

#checking if you have gentoolkit
if [ -f "/usr/bin/equery" ] ; then
    echo "gentoolkit found, continuing"
else 
    echo "please run ('emerge app-portage/gentoolkit') as root you will also benefit from the tools like equery or revdep-rebuild, others will ask you to emerge them anyways"
fi
OUT_TMP="/tmp/troubleshoot_$(date +%d%m%y_%H%M%S).txt" #the temporary file to be pasted online

#this function takes two arguments: analyze(comment_on_the_module, command_to_generate_desired_output)
function analyze 
{
    echo "MODULE---------------<<: ${1} :>>-----------------" >> $OUT_TMP
    echo "command ran: ${2}
    " >> $OUT_TMP
    $2 >> $OUT_TMP
    echo "


    " >> $OUT_TMP
}

#here come all the modules

analyze "RC Run Level Settings" "rc-status"
analyze "Window Manager info" "qlist -IC x11-wm"
analyze "fstab settings" "cat /etc/fstab"
analyze "Disk Usage & Statistics" "df -hT"
analyze "settings from make.conf" "cat /etc/make.conf"
analyze "portage info" "emerge --info"
analyze "what portage profile is used" "eselect profile list"
analyze "what kernel is used" "eselect kernel list"
analyze "PCI hardware" "lspci -k"
analyze "Loaded Modules" "lsmod"
analyze "DBUS rules" "ls -1 /etc/udev/rules.d/"
analyze "is dbus-session set" "echo ${DBUS_SESSION_BUS_ADDRESS}"
analyze "is consolekit set" "ck-list-sessions"
read -p "PLEASE ANSWER: what Desktop environment and/or Window manager are you using?   " wm #needed for DE question
analyze "WM/DE info" "echo $wm"
analyze "exported shell variables" "export"
analyze "username" "echo ${USER}"
analyze "hostname" "echo ${HOSTNAME}"
analyze "network status" "ifconfig"
analyze "Routing Tables" "route"
analyze "DNS Servers" "cat /etc/resolv.conf"



# at last, let's upload the info
wgetpaste $OUT_TMP

echo "your system info is at ${OUT_TMP}"
exit 0

