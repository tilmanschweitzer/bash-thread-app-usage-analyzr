#!/usr/bin/env bash



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



# ===== Parse parameters =====

folder=$1
file_number=$2
cpu_first_entry=$3
cpu_number_of_entries=$4
cpu_file_prefix="app_cpu_usage."
threads_file_prefix="app_threads."



# ===== Parameter checks =====

if [[ ! -d $folder ]]; then
    echo "ERROR: Folder '$folder' not found"
    exit;
fi

cd $folder

if [[ ! "$file_number" =~ ^[0-9]+$ ]]; then
    echo "ERROR: Given file number is invalid: '$file_number'"
    printf "Available file numbers: "
    ls $threads_file_prefix* | rev | cut -d "-" -f 1 | rev | sed s/.txt// | sed -e 's/^0*//' | xargs printf "%d "
    exit;
fi

if [[ ! "$cpu_first_entry" =~ ^[0-9]+$ ]]; then
    cpu_first_entry=1;
    echo "WARNING: Third parameter missing."
    echo "Specify a number of the first cpu usage entry next time."
    echo
    continue_with_script "Now, proceed with default value: $cpu_first_entry?"
fi

if [[ ! "$cpu_number_of_entries" =~ ^[0-9]+$ ]]; then
    cpu_number_of_entries=5;
    echo "WARNING: Forth parameter missing."
    echo "Specify a number of cpu usage entries next time."
    echo
    continue_with_script "Now, proceed with default value: $cpu_number_of_entries?"
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


