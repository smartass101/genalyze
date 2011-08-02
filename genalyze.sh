#!/bin/bash
#genalyze.sh
#this script gathers some data about your system and pastes them online 
#for other people, so that they can help you with your problem
# this script is perfectly safe if run as normal user, you may need to be root
# to emerge wgetpaste though 


PATH="${PATH}:/usr/sbin:/sbin" #this is needed for utils like lspci


out_tmp="/tmp/genalyze_output_$(date +%d%m%y_%H%M%S).txt" #the temporary file to be pasted online
interactive=1
readonly=0

2>>"${out_tmp}" #redirect stderr to the file (like 'command not found')

######################<< MODULE CLASSES (well, just bash functions,really) >>##############

#this function takes two arguments: analyze(comment_on_the_module, command_to_generate_desired_output)
function analyze 
{
    echo "############################## ${1} ##############################" >> "${out_tmp}"
    echo -e "--->>>command executed: ${2}\n" >> "${out_tmp}"
    $2 >> "${out_tmp}" 2>> "${out_tmp}"
    echo -e "\n\n" >> "${out_tmp}"
}

#this function takes arguments like (module), but asks if they should be run
function analyze_opt 
{
    while true ; do
        read -p " << ${1} >> command to be run: \" ${2} \"   ANSWER: Y/n :  "
        case ${REPLY} in
            y|Y|"") 
                echo "############################## ${1} ##############################" >> "${out_tmp}"
                echo -e "--->>>command executed: ${2}\n" >> "${out_tmp}"
                $2 >> "${out_tmp}" 2>>"${out_tmp}"
                echo -e "\n\n" >> "${out_tmp}"
                break;;
            n|N)
                echo ">>> skipping module << ${1} >>"
                break;;
            *)
                echo ">>> didn't understand you, type 'y' or 'n'";;
        esac 
   done
}

#this function just asks the user about stuff, takes two arguments: query(module_name, the_question_to_the_user)
function query
{
    read -p "PLEASE ANSWER (type,then press ENTER): ${2} ?  "
    echo "############################## ${1} ##############################" >> "${out_tmp}"
    echo -e "--->>> question asked: ${2}\n" >> "${out_tmp}"
    echo $REPLY >> "${out_tmp}"
    echo -e "\n\n" >> "${out_tmp}"
}
    
###############################<< MODULE DECLARATION >>################################

# format: module_identifier=( "module description " "command to be executed/question to be asked") 
# module_identifier: short, no whitespace (is used for referencing)
# module description: capitalised, and no abbreviations please, should be understandable for everyone


rc_status=( "RC Run Level Settings" "rc-status")
fstab=("Fstab Settings" "cat /etc/fstab")
du=("Disk Usage & Statistics" "df -hT")
makeconf=("Settings from /etc/make.conf" "cat /etc/make.conf")
portage=("General Portage Information" "emerge --info")
profiles=("Display of Portage Profiles" "eselect profile list")
kernel=("Kernel in use" "eselect kernel list")
hardware=("PCI Hardware" "lspci -k")
modules=("Modules Currently Loaded" "lsmod")
udev=("UDEV Rules" "ls -1 /etc/udev/rules.d/")
dbus=("DBUS-session Information" "echo ${DBUS_SESSION_BUS_ADDRESS}")
consolekit=("Consolekit-session Information" "ck-list-sessions")
wm=("Window Manager / Desktop Environment Information" "what Desktop environment and/or Window manager are you using")
exported=("Exported shell variables" "export")
username=("Username" "echo ${USER}")
hostname=("Hostname" "echo ${HOSTNAME}")
groups=("Group Membership" "groups")
ifconfig=("Network status" "ifconfig")
route=("Routing Tables" "route")
dns=("DNS Servers" "cat /etc/resolv.conf")


#######################################<<MODULE ARRAYS>>################################
#format: class_array=( module_identifier_1 module_identifier_2 .. )
analyze_array=(rc_status fstab du makeconf portage profiles kernel hardware modules udev dbus consolekit username hostname)
analyze_opt_array=(exported groups ifconfig route dns)
query_array=(wm)


##########################<< COMMAND LINE OPTIONS PROCESSING >>#######################

while [ $# -gt 0 ] ; do
    case $1 in
        -h|--help)
            echo "This bash script gathers information about your system and (optionally) uploads it"
            echo "through wgetpaste. It is intended for support purposes on the #gentoo IRC support channel
            "
            echo "Usage: genalyze [options]
            "
            echo "Options:"
            echo "-h, --help                            Display this message and exit"
            echo "-n, --non-interactive                 Do not ask questions, assume default values, upload"
            echo "-o, --omit <module_identifiers>       Do not execute specified modules"
            echo "-w, --with-only <module_identifiers>  Execute explicitly only these modules"
            echo "-r, --read-only                       Only display the file with information, don't upload"
            echo "-l, --list                            List available modules and exit"
            exit 0;;
        -n|--non-interactive)
            interactive=0
            analyze_opt_array=()
            query_array=()
            shift;;
        -d|--no-upload)
            UPLOAD=0
            shift;;
        -r|--read-only)
            readonly=1
            shift;;
        -l|--list)
            list_array=( ${analyze_array[@]} ${analyze_opt_array[@]} ${query_array[@]} )
            echo -e "<module identifier> :: <module description> :: <command executed by module>"
            for mod in ${list_array[@]} ; do
                eval echo  ${mod} " :: " \${$mod[0]} " :: " \${$mod[1]} #TODO make a table layout
            done
            exit 0;;
        -w|--with-only)
            shift
            analyze_array=()
            analyze_opt_array=()
            query_array=()
            until [[ $1 =~ -.* || $# -eq 0 ]] ; do
                analyze_array=( ${analyze_array[@]} $1 )
                shift
            done;;
        -o|--omit)
            shift
            until [[ $1 =~ -.* || $# -eq 0 ]] ; do
                analyze_array=${analyze_array#$1}
                analyze_opt_array=${analyze_array#$1}
                query_array=${analyze_array#$1}
                shift
            done;;
        *)
            echo ">>> unknown option, try --help"
            exit 1;;
    esac
done

##################################<<MODULE EXECUTION>>##############################3
#loops over class arrays and executes functions

echo ">>> Starting the genalyze script, collecting system information ..." 

#analyze()
for mod in ${analyze_array[@]}; do
    eval name=\${$mod[0]} 
    eval command=\${$mod[1]}
    analyze "${name}" "${command}"
done
#analyze_opt()
echo -e ">>> The following modules are optional. Answer [y]es if you would like to supply this information or [n]o if not.\n>>> You may just hit <ENTER> which defaults to answering 'yes'."
for mod in ${analyze_opt_array[@]}; do
    eval name=\${$mod[0]} 
    eval command=\${$mod[1]}
    analyze_opt "${name}" "${command}"
done
#query()
for mod in ${query_array[@]}; do
    eval name=\${$mod[0]} 
    eval command=\${$mod[1]}
    query "${name}" "${command}"
done

########################<<ENDING SEQUENCE>>#############################
echo ">>> your system info is at ${out_tmp}"

if [ $interactive -eq 0 ] ; then
    wgetpaste "${out_tmp}"
    exit 0
elif [ $readonly -eq 1 ] ; then
    less "${out_tmp}"
else
    while true ; do
        read -n 1 -e -p ">>> What do you want to do now? 
        [u]pload system info file through wgetpaste
        [r]ead the file with 'less'
        [q]uit
        ANSWER: type 'u' or 'r' or 'q' :  "
        case $REPLY in
            u)
                wgetpaste "${out_tmp}";;
            r)
                less "${out_tmp}";;
            q)
                break;;
            *)
                echo "couldn't understand you, try again";;
        esac
    done
fi

echo "    >>> Thank you for your cooperation :) <<<<   "
exit 0

