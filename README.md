# Bash thread cpu usage analyzr

> Analyse threads dumps and corresponding cpu usage information



## Collect the information

The thread dumps and cpu usage information can be collected by the [support info collector](https://bitbucket.apps.seibert-media.net/projects/SMEDIA/repos/isac/browse/bw/bundles/jdk/files/support-info-collector#82)


## Usage

Output of `./analyze-thread-app-usage.sh --help`:
    
    usage: ./analyze-thread-app-usage.sh --folder <path>
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
    
        --first-cpu-entry           Number of the first used entry for the report (default: 1)
        --number-of-cpu-entries     Number of entries analyzed (default 10)
        --cpu-threshold             Threshold for the entries
        --no-usage-table            Don't show the usage table
    
    Stack trace options
    
        --trace-max-lines           Max lines for the stack trace (default 100)
        --trace-until-package       Trace until a specific java package (example: net.seibertmedia)
        --trace-highlight-package   Highlight one or multiple java package s(example: net.seibertmedia|com.atlassian)
        --only-matching-package     Only show trace with matching java package (example: net.seibertmedia)
    
    Other
    
        --no-interaction            Skip confirmation questions and less
    
    Version
        --version                   Show only the script version
    
    Current Version: 0.1.0
    
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
