#!/bin/sh
# Time Machine
# - an rsync backup script
# - version 0.1
# 
# Based on the template provided by Michael Jakl
# taken from his own blog post found at:
# http://blog.interlinked.org/tutorials/rsync_time_machine.html
# and improved by Matteo Pescarin <peach[AT]smartart.it>
# 
# This code is provided 'as-is'
# and released under the GPLv3

SYNC_DIRS=''
SOURCE_DIR=`pwd`
TARGET_DIR=""
VERSION="0.1"
NO_ARGS=0 
E_OPTERROR=85
E_GENERROR=25
OLD_IFS="$IFS"
IFS=','

function usage() {
    echo -e "Syntax: `basename $0` [-h|-v] [-s <SYNC_DIR_1>[,<SYNC_DIR_2>[,...]]] [-b BACKUP_DIR] <SOURCE_DIR> <TARGET_DIR>
\t-h: shows this help
\t-v: be verbose
\t-s <SYNC_DIR_1>[,<SYNC_DIR_2>[,...]]: (comma-separated) list of dirs paths to be
\t\t synched back. The paths must be relative to the exec dir.
\t-b <BACKUP_DIR>: the backup directory where the to put the backup (tar.bz2 format)
\t<SOURCE_DIR>: directory to be used as source
\t<TARGET_DIR>: the destination directory, if not existing it'll be created.
\n"
}

function version() {
    echo -e "`basename $0` - Directory Synchroniser - version $VERSION\n"
}

function error() {
    version
    echo -e "Wrong parameters passed: $1\n"
    usage
}

if [ $# -eq "$NO_ARGS" ]
then
    version
    usage
    exit $E_OPTERROR
fi

# The expected flags are
#  h v r
while getopts ":hvs:b:" Option
do
    case $Option in
        h ) version
            usage
            exit 0;;
        v ) BE_VERBOSE=true;;
        s ) SYNC_DIRS=$OPTARG
			SYNC_BACK=true;;
        b ) [ ! -e $OPTARG ] && error "$OPTARG not accessible" && exit $E_OPTERROR
            BACKUP_DIR=$OPTARG;;
    esac
done

#  Decrements the argument pointer so it points to next argument.
#  $1 now references the first non-option item supplied on the command-line
#+ if one exists.
shift $(($OPTIND - 1))

# check the dest and source dirs are ok and normalise the paths
if [ $# -eq 2 ]
then
    SOURCE_DIR=$1
    TARGET_DIR=$2
else if [ $# -eq 1 ]
then
    TARGET_DIR=$1
else
    

# Split the directories to sync back
if [ -n $SYNC_BACK ]
then
    read -ar SYNC_DIRS <<< "$SYNC_DIRS"
    for dir in $SYNC_DIRS
    do
        if [[ -e $dir ]]
        rsync -az --delete $dir
    done
fi

rsync -az --delete $SOURCE_DIR $SYNCBACK

IFS=$OLD_IFS
exit
