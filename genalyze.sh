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

######################<< MODULE CLASSES (well, just bash functions,really) >>##############

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
    echo "############################## ${1} ##############################" >> $OUT_TMP
    echo "--->>> question asked: ${2}
    " >> $OUT_TMP
    echo $REPLY >> $OUT_TMP
    echo "


    " >> $OUT_TMP
}
    
###############################<< MODULE DECLARATION >>################################

# format: declare -A module_identifier=( ["module name to be displayed"]="command to be executed/question to be asked") 
# module_identifier: short, no whitespace (is used for referencing)
# module name: capitalised module naming, and no abbreviations please, should be understandable for everyone


declare -A rc_status=( ["RC Run Level Settings"]="rc-status")
declare -A fstab=(["Fstab Settings"]="cat /etc/fstab")
declare -A du=(["Disk Usage & Statistics"]="df -hT")
declare -A makeconf=(["Settings from /etc/make.conf"]="cat /etc/make.conf")
declare -A portage=(["General Portage Information"]="emerge --info")
declare -A profiles=(["Display of Portage Profiles"]="eselect profile list")
declare -A kernel=(["Kernel in use"]="eselect kernel list")
declare -A hardware=(["PCI Hardware"]="lspci -k")
declare -A modules=(["Modules Currently Loaded"]="lsmod")
declare -A udev=(["UDEV Rules"]="ls -1 /etc/udev/rules.d/")
declare -A dbus=(["DBUS-session Information"]="echo ${DBUS_SESSION_BUS_ADDRESS}")
declare -A consolekit=(["Consolekit-session Information"]="ck-list-sessions")
declare -A wm=(["Window Manager / Desktop Environment Information"]="what Desktop environment and/or Window manager are you using")
declare -A exported=(["Exported shell variables"]="export")
declare -A username=(["Username"]="echo ${USER}")
declare -A hostname=(["Hostname"]="echo ${HOSTNAME}")
declare -A ifconfig=(["Network status"]="ifconfig")
declare -A route=(["Routing Tables"]="route")
declare -A dns=(["DNS Servers"]="cat /etc/resolv.conf")


#######################################<<MODULE ARRAYS>>################################
#format: class_array=( module_identifier_1 module_identifier_2 .. )
analyze_array=(rc_status fstab du makeconf portage profiles kernel hardware modules udev dbus consolekit username hostname)
analyze_opt_array=(exported ifconfig route dns)
query_array=(wm)


##########################<< COMMAND LINE OPTIONS PROCESSING >>#######################

while 

##################################<<MODULE EXECUTION>>##############################3
#loops over class arrays and executes functions

#analyze()
for mod in ${analyze_array[@]}; do
    eval name=\${\!$mod[@]} 
    eval command=\${$mod[@]}
    analyze "${name}" "${command}"
done
#analyze_opt()
for mod in ${analyze_opt_array[@]}; do
    eval name=\${\!$mod[@]} 
    eval command=\${$mod[@]}
    analyze_opt "${name}" "${command}"
done
#query()
for mod in ${query_array[@]}; do
    eval name=\${\!$mod[@]} 
    eval command=\${$mod[@]}
    query "${name}" "${command}"
done

########################<<ENDING SEQUENCE>>#############################
echo ">>> your system info is at ${OUT_TMP}"

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

