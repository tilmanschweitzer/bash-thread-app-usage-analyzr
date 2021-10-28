# Bash thread cpu usage analyzr

> Analyse threads dumps and corresponding cpu usage information



## Collect the information

The thread dumps and cpu usage information can be collected by the [support info collector](https://bitbucket.apps.seibert-media.net/projects/SMEDIA/repos/isac/browse/bw/bundles/jdk/files/support-info-collector#82)


## Usage

Just use the help

    ./analyze-thread-app-usage.sh --help
    
    usage: ./analyze-thread-app-usage.sh --folder <path> --file-number=<file-number>
                            [--first-cpu-entry <entry-number>]
                            [--number-of-cpu-entries <number>]
                            [--help]
                            [--version]
    
    Required parameters
    
        --folder                    Folder containing the thread dumps and cpu usage information
        --file-number               Number of the file in the folder
    
    Specify entry in cpu usage file
    
        --first-cpu-entry           Number of the first used entry for the report (default: 1)
        --number-of-cpu-entries     Number of entries analyzed (default 5)
    
    Version
        --version                   Show only the script version
    
    Current Version: 0.0.1
    
# Examples

    ./analyze-thread-app-usage.sh --folder ../Customer-A/threads-2020-02-10--07-00-02/ \
        --file-number 2 
    
    ./analyze-thread-app-usage.sh --folder ../Customer-A/threads-2020-02-10--07-00-02/ \
        --file-number 2 \
        --number-of-cpu-entries 10


    ./analyze-thread-app-usage.sh --folder ../Customer-A/threads-2020-02-10--07-00-02/ \
        --file-number 2 \
        --number-of-cpu-entries 10 \
        --no-interaction \
        --trace-highlight-package "com.atlassian|sun.reflect"
    
    
    com.atlassian.confluence.plugins.questions
