#!/bin/sh
#genalyze.sh
#this script gathers some data about your system and pastes them online 
#for other people, so that they can help you with your problem
# this script is perfectly safe if run as normal user, you may need to be root
# to emerge wgetpaste though 

 
PATH="${PATH}:/usr/sbin:/sbin" #this is needed for utils like lspci

WGETPASTE="/usr/bin/wgetpaste" #binary for pasting online
#checking if you have wgetpaste
if [ -f $WGETPASTE ] ; then echo ">>> wgetpaste found, continuing"
else ">>> please emerge wgetpaste (run as root 'emerge wgetpaste') and then run this script again"; exit 1;
fi

#checking if you have gentoolkit
if [ -f "/usr/bin/equery" ] ; then
    echo ">>> gentoolkit found, continuing"
else 
    echo ">>> please run ('emerge app-portage/gentoolkit') as root you will also benefit from the tools like equery or revdep-rebuild, others will ask you to emerge them anyways"
fi

OUT_TMP="/tmp/genalyze_output_$(date +%d%m%y_%H%M%S).txt" #the temporary file to be pasted online

2>>$OUT_TMP #redirect stderr to the file (like 'command not found')

#-----------<< MODULE CLASSES (well, just bash functions,really) >>---------

#this function takes two arguments: analyze(comment_on_the_module, command_to_generate_desired_output)
function analyze 
{
    echo "############################## ${1} ##############################" >> $OUT_TMP
    echo "--->>>command executed: ${2}
    " >> $OUT_TMP
    $2 >> $OUT_TMP
    echo "


    " >> $OUT_TMP
}

#this function takes arguments like (module), but asks if they should be run
function analyze_opt 
{
    while true ; do
        read -p "OPTIONAL: do you want to supply this information ? << ${1} >> 
command to be run: ${2}   ANSWER: type 'y' or 'n' :  "
        case ${REPLY} in
            y) 
                echo "MODULE---------------<<: ${1} :>>-----------------" >> $OUT_TMP
                echo "::::command run: ${2}
                " >> $OUT_TMP
                $2 >> $OUT_TMP
                echo "


                " >> $OUT_TMP
                break;;
            n)
                echo "skipping module << ${1} >>"
                break;;
            *)
                echo ">>>didn't understand you, type 'y' or 'n'";;
        esac 
   done
}

#this function just asks the user about stuff, takes two arguments: query(module_name, the_question_to_the_user)
function query
{
    read -p "PLEASE ANSWER (type,then press ENTER): ${2} ?  "
    echo "MODULE---------------<<: ${1} :>>-----------------" >> $OUT_TMP
    echo ":::QUERY: ${2}
    " >> $OUT_TMP
    echo $REPLY >> $OUT_TMP
    echo "


    " >> $OUT_TMP
}
    
#--------<< MODULE LISTING >>-------

analyze "RC Run Level Settings" "rc-status"
# analyze "Window Manager info" "qlist -IC x11-wm" #this tools isn't standard
analyze "fstab settings" "cat /etc/fstab"
analyze_opt "Disk Usage & Statistics" "df -hT"
analyze "Settings from make.conf" "cat /etc/make.conf"
analyze "portage info" "emerge --info"
analyze "What portage profile is used" "eselect profile list"
analyze "What kernel is used" "eselect kernel list"
analyze "PCI hardware" "lspci -k"
analyze "Loaded Modules" "lsmod"
analyze "DBUS rules" "ls -1 /etc/udev/rules.d/"
analyze "Is dbus-session set" "echo ${DBUS_SESSION_BUS_ADDRESS}"
analyze "Is consolekit set" "ck-list-sessions"
query "WM/DE info" "what Desktop environment and/or Window manager are you using"
analyze_opt "Exported shell variables" "export"
analyze "username" "echo ${USER}"
analyze "hostname" "echo ${HOSTNAME}"
analyze_opt "Network status" "ifconfig"
analyze_opt "Routing Tables" "route"
analyze_opt "DNS Servers" "cat /etc/resolv.conf"


echo ">>> your system info is at ${OUT_TMP}"

#-------<< ENDING SEQUENCE >>-----
while true ; do
    read -p ">>> What do you want to do now? 
    [u]pload system info file through wgetpaste
    [r]ead the file with 'less'
    [e]xit
    ANSWER: type 'u' or 'r' or 'e' :  "
    case $REPLY in
        u)
            wgetpaste $OUT_TMP;;
        r)
            less $OUT_TMP;;
        e)
            echo "    >>> Thank you for your cooperation :) <<<<   "
            break;;
        *)
            echo "couldn't understand you, try again";;
    esac
done

exit 0

