#!/usr/bin/env bash

version="0.0.1"

all_params="${*} "

# ===== Constants =====

default_cpu_first_entry=1
default_cpu_number_of_entries=10
default_max_lines=100
cpu_file_prefix="app_cpu_usage."
threads_file_prefix="app_threads."

# ===== Functions =====

function continue_with_script {
    if [[ -n $no_interaction_flag ]]; then
        return;
    fi

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
    echo "usage: $0 --folder <path>
                        [--file-number=<file-number>]
                        [--file-suffix=<file-suffix>]
                        [--first-cpu-entry <entry-number>]
                        [--number-of-cpu-entries <number>]
                        [--cpu-threshold <cpu-usage-percent>]
                        [--no-usage-table]
                        [--trace-max-lines <max-lines>]
                        [--trace-until-package <package-name>]
                        [--trace-highlight-package <package-name>]
                        [--only-matching-package <package-name>]
                        [--help]
                        [--version]

Required parameters

    --folder                    Folder containing the thread dumps and cpu usage information

Specify a file

    --file-number               Number of the file in the folder
    --file-suffix               Suffix of the file in the folder (example: 2020-02-27--12-20-02-1)

Specify entry in cpu usage file

    --first-cpu-entry           Number of the first used entry for the report (default: $default_cpu_first_entry)
    --number-of-cpu-entries     Number of entries analyzed (default $default_cpu_number_of_entries)
    --cpu-threshold             Threshold for the entries
    --no-usage-table            Don't show the usage table

Stack trace options

    --trace-max-lines           Max lines for the stack trace (default $default_max_lines)
    --trace-until-package       Trace until a specific java package (example: net.seibertmedia)
    --trace-highlight-package   Highlight one or multiple java package s(example: net.seibertmedia|com.atlassian)
    --only-matching-package     Only show trace with matching java package (example: net.seibertmedia)

Other

    --no-interaction            Skip confirmation questions and less

Version
    --version                   Show only the script version

Current Version: $version

"
}



# ===== Parse parameters =====

folder=$(regex_parse_helper "${all_params}" "--folder ([^[:space:]]+)")
file_number=$(regex_parse_helper "${all_params}" "--file-number ([0-9]+)")
file_suffix=$(regex_parse_helper "${all_params}" "--file-suffix ([^[:space:]]+)")
cpu_first_entry=$(regex_parse_helper "${all_params}" "--first-cpu-entry ([0-9]+)")
cpu_number_of_entries=$(regex_parse_helper "${all_params}" "--number-of-cpu-entries ([0-9]+)")
cpu_usage_threshold=$(regex_parse_helper "${all_params}" "--cpu-threshold ([0-9]+)")
max_lines=$(regex_parse_helper "${all_params}" "--trace-max-lines ([0-9]+)")
trace_until_package=$(regex_parse_helper "${all_params}" "--trace-until-package ([^[:space:]]+)")
trace_highlight_package=$(regex_parse_helper "${all_params}" "--trace-highlight-package ([^[:space:]]+)")
only_matching_package=$(regex_parse_helper "${all_params}" "--only-matching-package ([^[:space:]]+)")
help_flag=$(regex_parse_helper "${all_params}" "(--help) ")
version_flag=$(regex_parse_helper "${all_params}" "(--version) ")
no_interaction_flag=$(regex_parse_helper "${all_params}" "(--no-interaction) ")
no_usage_table_flag=$(regex_parse_helper "${all_params}" "(--no-usage-table) ")


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

if [[ ! "$cpu_first_entry" =~ ^[0-9]+$ ]]; then
    cpu_first_entry=$default_cpu_first_entry;
    echo "INFO: Parameter --first-cpu-entry missing. The script proceeds with the default value: $default_cpu_first_entry"
fi

if [[ ! "$cpu_number_of_entries" =~ ^[0-9]+$ ]]; then
    cpu_number_of_entries=$default_cpu_number_of_entries;
    echo "INFO: Parameter --number-of-cpu-entries missing. The script proceeds with the default value: $default_cpu_number_of_entries"
fi

if [[ ! "$max_lines" =~ ^[0-9]+$ ]]; then
    max_lines=$default_max_lines;
    echo "INFO: Parameter --trace-max-lines missing. The script proceeds with the default value: $default_max_lines"
fi


# ===== Analyse function =====

global_thread_counter=1

function analyse_file_with_name {
    current_cpu_file=$1
    current_threads_file=$2



    cpu_line=$(expr 6 + $cpu_first_entry + $cpu_number_of_entries)
    cpu_line_content="$(head -n $cpu_line $current_cpu_file | tail -n $cpu_number_of_entries)"



    # ===== Print parameter information =====

    echo
    echo "Analyse $current_cpu_file and $current_threads_file"
    echo
    if [[ -n "$no_usage_table_flag" ]]; then
        printf "$cpu_line_content" | grep -n '^'
        echo
        echo
    fi


    # ===== Process cpu usage information and find matching threads =====

    IFS=$'\n'

    thread_number=$cpu_first_entry
    count_matches=0

    for line in $(printf "$cpu_line_content"); do
        trimmed_line=$(printf "$line" | sed -e 's/^ *//' | sed -e's/  */ /g')
        pid=$(printf "$trimmed_line" | cut -d " " -f 1)
        hex_pid=$(printf "%#x" $pid)
        cpu_usage=$(printf "$trimmed_line" | cut -d " " -f 9)
        mem_usage=$(printf "$trimmed_line" | cut -d " " -f 10)


        if [[ -n "$cpu_usage_threshold" ]] && [[ $(echo "$cpu_usage" | cut -d "." -f 1) -lt "$cpu_usage_threshold" ]]; then
            break;
        fi

        if [[ -n "$file_number" ]] || [[ -n "$file_suffix" ]]; then
            display_thread_number=$thread_number
        else
            display_thread_number=$global_thread_counter
            global_thread_counter=$(expr 1 + $global_thread_counter)
        fi

        echo "${display_thread_number}. Thread $hex_pid with $cpu_usage% cpu and $mem_usage% memory usage"
        thread_number=$(expr $thread_number + 1)

        if [[ -z "$trace_until_package" ]]; then
            thread_dump_entry_limit_regex="^$"
        else
            thread_dump_entry_limit_regex="(^$|$trace_until_package)"
        fi

        thread_dump_entry="$(awk "/${hex_pid}/,/$thread_dump_entry_limit_regex/" $current_threads_file)"

        if [[ -n "$only_matching_package" ]] && [[ -z "$(printf "$thread_dump_entry" | grep "$only_matching_package")" ]]; then
            echo "No match package: '$only_matching_package'"
            echo
            continue;
        fi
        count_matches=$(expr $count_matches + 1)



        highlight_regex="$"

        if [[ -n "$trace_highlight_package" ]]; then
            highlight_regex="$trace_highlight_package|$highlight_regex"
        fi

        if [[ -n "$trace_until_package" ]]; then
            highlight_regex="$trace_until_package|$highlight_regex"
        fi

        printf "${thread_dump_entry}\n" | head -n $max_lines | grep --color=always -E "${highlight_regex}"

        if [[ -z "$no_interaction_flag" ]]; then
             printf "${thread_dump_entry}\n" | less --quit-if-one-screen
        fi
        echo

        continue_with_script "Next thread?"
    done


    if [[ -n "$only_matching_package" ]]; then
        echo
        echo "Found $count_matches matches for package '$only_matching_package'"
    fi

}


# ===== Run with given file number =====
if [[ -n "$file_number" ]]; then
    if [[ ! "$file_number" =~ ^[0-9]+$ ]]; then
        echo "ERROR: Parameter --file-number is invalid: '$file_number'"
        printf "Available file numbers: "
        ls $threads_file_prefix* | rev | cut -d "-" -f 1 | rev | sed s/.txt// | sed -e 's/^0*//' | xargs printf "%d "
        echo "Use --help for further documentation"
        exit;
    fi

    timestamp=$(ls ${cpu_file_prefix}* | head -n 1 | sed s/-01.txt// | sed s/${cpu_file_prefix}//)

    current_cpu_file="${cpu_file_prefix}${timestamp}-$(printf "%02d" $file_number).txt"
    current_threads_file="${threads_file_prefix}${timestamp}-$(printf "%02d" $file_number).txt"

    analyse_file_with_name "$current_cpu_file" "$current_threads_file"

    exit
fi

if [[ -n "$file_suffix" ]]; then
    current_cpu_file="${cpu_file_prefix}${file_suffix}.txt"
    current_threads_file="${threads_file_prefix}${file_suffix}.txt"
    analyse_file_with_name "$current_cpu_file" "$current_threads_file"
    exit
fi

# ===== Run with given file suffix =====


for suffix in $(ls $cpu_file_prefix* | sed "s/$cpu_file_prefix//"); do

    current_cpu_file="${cpu_file_prefix}${suffix}"
    current_threads_file="${threads_file_prefix}${suffix}"

    analyse_file_with_name "$current_cpu_file" "$current_threads_file"

    echo "===================="
done
