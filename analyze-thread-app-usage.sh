#!/usr/bin/env bash

version="0.0.1"

all_params="${*} "

# ===== Constants =====

default_cpu_first_entry=1
default_cpu_number_of_entries=5;
cpu_file_prefix="app_cpu_usage."
threads_file_prefix="app_threads."

# ===== Functions =====

function continue_with_script {
    message=$1
    while true; do
        read -p "$message (y/n) " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no. (y/n)";;
        esac
    done
}

function regex_parse_helper {
    CONTENT=$1
    REGEX=$2
    GROUP=$3

    if [ -z $GROUP ]; then
        GROUP=1
    fi;

    if [[ $CONTENT =~ $REGEX ]]; then
        echo "${BASH_REMATCH[$GROUP]}"
    else
        exit 1
    fi
}

function help {
    echo "usage: $0 --folder <path> --file-number=<file-number>
                        [--first-cpu-entry <entry-number>]
                        [--number-of-cpu-entries <number>]
                        [--help]
                        [--version]

Required parameters

    --folder                    Folder containing the thread dumps and cpu usage information
    --file-number               Number of the file in the folder

Specify entry in cpu usage file

    --first-cpu-entry           Number of the first used entry for the report (default: $default_cpu_first_entry)
    --number-of-cpu-entries     Number of entries analyzed (default $default_cpu_number_of_entries)

Version
    --version                   Show only the script version

Current Version: $version

"
}



# ===== Parse parameters =====

folder=$(regex_parse_helper "${all_params}" "--folder ([^[:space:]]+)")
file_number=$(regex_parse_helper "${all_params}" "--file-number ([0-9]+)")
cpu_first_entry=$(regex_parse_helper "${all_params}" "--first-cpu-entry ([0-9]+)")
cpu_number_of_entries=$(regex_parse_helper "${all_params}" "--number-of-cpu-entries ([0-9]+)")
help_flag=$(regex_parse_helper "${all_params}" "(--help) ")
version_flag=$(regex_parse_helper "${all_params}" "(--version) ")


# ===== Parameter checks =====

if [[ -n $help_flag ]]; then
    help
    exit
fi

if [[ -n $version_flag ]]; then
    echo "Version: $version"
    exit
fi

if [[ ! -d $folder ]]; then
    echo "ERROR: Folder '$folder' not found"
    echo "Use --help for further documentation"
    exit;
fi

cd $folder

if [[ ! "$file_number" =~ ^[0-9]+$ ]]; then
    echo "ERROR: Parameter --file-number is invalid: '$file_number'"
    printf "Available file numbers: "
    ls $threads_file_prefix* | rev | cut -d "-" -f 1 | rev | sed s/.txt// | sed -e 's/^0*//' | xargs printf "%d "
    echo "Use --help for further documentation"
    exit;
fi

if [[ ! "$cpu_first_entry" =~ ^[0-9]+$ ]]; then
    cpu_first_entry=$default_cpu_first_entry;
    echo "INFO: Parameter --first-cpu-entry missing. The script proceeds with the default value: $default_cpu_first_entry"
fi

if [[ ! "$cpu_number_of_entries" =~ ^[0-9]+$ ]]; then
    cpu_number_of_entries=$default_cpu_number_of_entries;
    echo "INFO: Parameter --number-of-cpu-entries missing. The script proceeds with the default value: $default_cpu_number_of_entries"

fi

timestamp=$(ls ${cpu_file_prefix}* | head -n 1 | sed s/-01.txt// | sed s/${cpu_file_prefix}//)

current_cpu_file="${cpu_file_prefix}${timestamp}-$(printf "%02d" $file_number).txt"
current_threads_file="${threads_file_prefix}${timestamp}-$(printf "%02d" $file_number).txt"

cpu_line=$(expr 6 + $cpu_first_entry + $cpu_number_of_entries)
cpu_line_content="$(head -n $cpu_line $current_cpu_file | tail -n $cpu_number_of_entries)"



# ===== Print parameter information =====

echo
echo "Analyse $current_cpu_file and $current_threads_file"
echo
printf "$cpu_line_content" | grep -n '^'
echo
echo


# ===== Process cpu usage information and find matching threads =====

IFS=$'\n'

thread_number=$cpu_first_entry
for line in $(printf "$cpu_line_content"); do
    trimmed_line=$(printf "$line" | sed -e 's/^ *//' | sed -e's/  */ /g')
    pid=$(printf "$trimmed_line" | cut -d " " -f 1)
    hex_pid=$(printf "%#x" $pid)
    cpu_usage=$(printf "$trimmed_line" | cut -d " " -f 9)
    mem_usage=$(printf "$trimmed_line" | cut -d " " -f 10)

    echo "$thread_number Thread $hex_pid with $cpu_usage% cpu and $mem_usage% memory usage"
    thread_dump_entry="$(awk "/${hex_pid}/,/^$/" $current_threads_file)"
    printf "${thread_dump_entry}\n" | head -n 10
    printf "${thread_dump_entry}\n" | less --quit-if-one-screen
    echo

    continue_with_script "Next thread?"

    thread_number=$(expr $thread_number + 1)

done


