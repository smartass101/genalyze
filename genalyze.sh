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
                echo "############################## ${1} ##############################" >> $OUT_TMP
                echo "--->>>command executed: ${2}
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
# please use capitalised module naming, and no abbreviations please
analyze "RC Run Level Settings" "rc-status"
# analyze "Window Manager info" "qlist -IC x11-wm" #this tools isn't standard
analyze "Fstab Settings" "cat /etc/fstab"
analyze_opt "Disk Usage & Statistics" "df -hT"
analyze "Settings from /etc/make.conf" "cat /etc/make.conf"
analyze "General Portage Information" "emerge --info"
analyze "Display of Portage Profiles" "eselect profile list"
analyze "Kernel in use" "eselect kernel list"
analyze "PCI Hardware" "lspci -k"
analyze "Modules Currently Loaded" "lsmod"
analyze "DBUS Rules" "ls -1 /etc/udev/rules.d/"
analyze "DBUS-session Information" "echo ${DBUS_SESSION_BUS_ADDRESS}"
analyze "Consolekit-session Information" "ck-list-sessions"
query "WM/DE info" "what Desktop environment and/or Window manager are you using"
analyze_opt "Exported shell variables" "export"
analyze "Username" "echo ${USER}"
analyze "Hostname" "echo ${HOSTNAME}"
analyze_opt "Network status" "ifconfig"
analyze_opt "Routing Tables" "route"
analyze_opt "DNS Servers" "cat /etc/resolv.conf"


echo ">>> your system info is at ${OUT_TMP}"

#-------<< ENDING SEQUENCE >>-----
while true ; do
    read -p ">>> What do you want to do now? 
    [u]pload system info file through wgetpaste
    [r]ead the file with 'less'
    [q]uit
    ANSWER: type 'u' or 'r' or 'q' :  "
    case $REPLY in
        u)
            wgetpaste $OUT_TMP;;
        r)
            less $OUT_TMP;;
        q)
            echo "    >>> Thank you for your cooperation :) <<<<   "
            break;;
        *)
            echo "couldn't understand you, try again";;
    esac
done

exit 0

