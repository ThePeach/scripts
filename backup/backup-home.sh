#!/bin/bash
# Backup Home
# - an rsync-based backup script
# - version 0.1
# 
# Based on the template provided by Michael Jakl
# taken from his own blog post found at:
# http://blog.interlinked.org/tutorials/rsync_time_machine.html
# and improved by Matteo Pescarin <peach[AT]smartart.it>
# 
# This code is provided 'as-is'
# and released under the GPLv3

VERSION='0.1'
DATE=`date "+%Y-%m-%dT%H_%M_%S"`
HOME="/home/`whoami`/"
NO_ARGS=0 
E_OPTERROR=85
E_GENERROR=25
EXCLUDE_OPT=''
FILES_OPT=''
REMOTE_OPT=''

function usage() {
echo -e "Syntax: `basename $0` [-h|-v|-n] [-r <[user@]host>] [-e <exclude list>] [-f <file list>] [<source>] <dest>
\t-h: shows this help
\t-v: be verbose (otherwise just display the progress)
\t-r <[USER@]HOST>: will send the data via ssh to the remote host HOST using the user USER, if specified
\t-e <exclude list>: the exclude list, see rsync manual on how to create it. By default it will backup everything. Check -f option if you need more control.
\t-f <file list>: the list of files to transfer, see rsync manual on how to create it.
\t-n: do a dry run, don't actually backup anything, just check things are ready togo
\t<source>: specify the path to the source directory to backup will use /home/`whoami`/ if not specified
\t<dest>: the destination directory, if not existing it'll be created.
\n"
}

function version() {
    echo -e "`basename $0` - Backup - version $VERSION\n"
}

function description() {
    echo -e "This script will backup your home (or whichever dir you pass) to a destination directory. NOTE: It will also cleanup the destination directory (and any additionally passed exclusion list). Make sure to run it in dry mode first, before starting to swear.
"
}

function error() {
    version
    echo -e "Wrong parameters passed: $1\n"
    usage
}

if [ $# -eq "$NO_ARGS" ]
then
    version
    description
    usage
    exit $E_OPTERROR
fi

# The expected flags are
#  h v r
while getopts ":hvnr:e:f:" Option
do
    case $Option in
        h ) version
            description
            usage
            exit 0;;
        v ) BE_VERBOSE=true;;
        n ) DRYRUN_OPT=("-n");;
        r ) REMOTE_OPT=$OPTARG;;
        e ) [ ! -e $OPTARG ] && error "$OPTARG not accessible" && exit $E_OPTERROR
            EXCLUDE_OPT=("--delete-excluded --exclude-from=$OPTARG");;
        f ) [ ! -e $OPTARG ] && error "$OPTARG not accessible" && exit $E_OPTERROR
            FILES_OPT=("--files-from=$OPTARG");;
    esac
done

#  Decrements the argument pointer so it points to next argument.
#  $1 now references the first non-option item supplied on the command-line
#  if one exists.
shift $(($OPTIND - 1))

# sets source and destination for the backup
if [ $# -eq 2 ]
then
    SOURCE=$1
    DEST=$2
else
    SOURCE=$HOME
    DEST=$1
fi

if [ "$REMOTE_OPT" != "" ]
then
    DEST="$REMOTE_OPT:$DEST"
fi

if [ $BE_VERBOSE ]
then
    echo -e "
SOURCE=${SOURCE}
DEST=${DEST}
"
    VERBOSE_OPT=("-vvv")
fi

# checking the destination directory is fine
# TODO: should be checking if the destination dir exists also for remote hosts
# TODO: should check permissions are write enabled for the user
if [ ! -e "$DEST" ]
then
    echo "$DEST not found, creating it"
    mkdir -p "$DEST"
    if [ "$?" -ne 0 ]
    then
        echo "Error while creating the directory $DEST
Check your permissions!"
        exit $E_GENERROR
    fi
fi
# checking the dest is actually a directory
if [ ! -d "$DEST" ]
then
    echo "$DEST is not a dir, aborting"
    exit $E_GENERROR
fi

if [ -n "$DRYRUN_OPT" ]
then
    echo "Everything seems fine.
Dry-running the backup."
fi

rsync \
    -arz --stats --progress \
    --delete --delete-excluded \
    ${DRYRUN_OPT[@]} \
    ${VERBOSE_OPT[@]} \
    ${FILES_OPT[@]} \
    ${EXCLUDE_OPT[@]} \
    "$SOURCE" "$DEST"

if [ $? -ne 0 ]
then
    echo "Rsync failed miserably

Aborting now."
    exit $E_GENERROR
elif [ -n "$DRYRUN_OPT" ]
then
    exit
fi

exit

