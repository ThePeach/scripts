#!/bin/sh
# httpdocs sync
# - a synchroniser script for web directories
# - version 0.2
# - author: Matteo Pescarin <peach[AT]smartart.it>
#
# This script takes a source and a target dir and keeps them in sync with
# their content. It's possible to preserve some directories from the target dir
# doing a "sync-back" operation and specifying the list of dirs to keep.
# Optionally a backup can also be created before anything is moved.
# 
# This code is provided 'as-is'
# and released under the GPLv3

EXCLUDE_DIRS=''
EXCLUDE_OPT=""
SOURCE_DIR=`pwd`
TARGET_DIR=""
VERSION="0.2"
NO_ARGS=0 
E_OPTERROR=85
E_GENERROR=25
OLD_IFS="$IFS"
IFS=','

function usage() {
    echo -e "Syntax: `basename $0` [-h|-v] [-e <EXCLUDE_DIR_1>[,<EXCLUDE_DIR_2>[,...]]] [-b BACKUP_DIR] <SOURCE_DIR> <TARGET_DIR>
\t-h: shows this help
\t-v: be verbose
\t-n: dry run (don't actually execute the commands)
\t-e <EXCLUDE_DIR_1>[,<EXCLUDE_DIR_2>[,...]]: (comma-separated) list of dirs paths to be
\t\t synched back. The paths must be relative to the target dir.
\t-b <BACKUP_DIR>: the backup directory where the to put the backup in tar.bz2 format
\t\t of the whole TARGET_DIR before doing any synchronisation.
\t<SOURCE_DIR>: directory to be used as source
\t<TARGET_DIR>: the destination directory, if not existing it'll be created.
\n"
}

function version() {
    echo -e "`basename $0` - Directory Synchroniser - version $VERSION\n"
}

function error() {
    version
    echo -e "Error: $1\n"
    usage
}

function quit {
    IFS=$OLD_IFS
    exit $1
}

if [ $# -eq "$NO_ARGS" ]; then
    version
    usage
    quit $E_OPTERROR
fi

# The expected flags are
#  h v r
while getopts ":hnve:b:" Option
do
    case $Option in
        h ) version
            usage
            quit 0;;
        n ) DRYRUN_OPT=("-n");;
        v ) BE_VERBOSE=true
            VERBOSE_OPT=("-v");;
        e ) EXCLUDE_DIRS=$OPTARG
			EXCLUDE=true;;
        b ) [ ! -e $OPTARG ] && error "'$OPTARG' not accessible" && quit $E_OPTERROR
            BACKUP_DIR=$OPTARG;;
    esac
done

# Decrements the argument pointer so it points to next argument.
# $1 now references the first non-option item supplied on the command-line
# if one exists.
shift $(($OPTIND - 1))

# check the dest and source dirs are ok and normalise the paths
# the source must have a / delimiter
# the target must not
if [ $# -eq 2 ]; then
    SOURCE_DIR=$1
    [ `echo ${SOURCE_DIR} | grep [^/]$` ] && SOURCE_DIR="${SOURCE_DIR}/"
    TARGET_DIR=$2
    [ `echo ${TARGET_DIR} | grep /$` ] && TARGET_DIR="${TARGET_DIR%?}"
elif [ $# -eq 1 ]; then
    TARGET_DIR=$1
fi
# ensure source dir exists
if [ ! -e $SOURCE_DIR ]; then
    echo "Source dir '${SOURCE_DIR}' not found"
    quit $E_GENERROR 
fi
# ensure target dir exists
if [ ! -e $TARGET_DIR ]; then
    echo "Target dir '${TARGET_DIR}' not found"
    quit $E_GENERROR 
fi

[[ -n $BE_VERBOSE ]] && echo ">> SOURCE_DIR: ${SOURCE_DIR}"
[[ -n $BE_VERBOSE ]] && echo ">> TARGET_DIR: ${TARGET_DIR}"

if [[ -n $BACKUP_DIR ]]; then
    BACKUP_FILE="`date +%F-%H-%M`-${TARGET_DIR}.tar.bz2"
    [ `echo $BACKUP_DIR | grep [^/]$` ] && BACKUP_DIR="${BACKUP_DIR}/"
    [[ -n $BE_VERBOSE ]] && echo ">> BACKUP_DIR: ${BACKUP_DIR}"
    [[ -n $BE_VERBOSE ]] && echo ">> BACKUP_FILE: ${BACKUP_FILE}"
    echo ""
    [[ -n $BE_VERBOSE ]] && echo ">> Starting the backup"
    if [[ -n $DRYRUN_OPT ]]; then
        echo tar -cjpf "${BACKUP_DIR}${BACKUP_FILE}" "${TARGET_DIR}"
    else
        tar -cjpf ${VERBOSE_OPT[@]} "${BACKUP_DIR}${BACKUP_FILE}" "${TARGET_DIR}"
    fi
    # if the tar has failed, bail out
fi

    
# Split the directories to sync back
if [ -n $EXCLUDE ]; then
    read -ar EXCLUDE_DIRS <<< "$EXCLUDE_DIRS"
    for dir in $EXCLUDE_DIRS
    do
        if [[ ! -e "${TARGET_DIR}/${dir}" ]]; then
            echo "Excluded dir ${TARGET_DIR}/${dir} not found!"
            quit $E_GENERROR
        elif [ -n $BE_VERBOSE ]; then
            echo ">> Excluded dir: ${TARGET_DIR}/${dir}"
        fi
    done
    # if we are here we can start doing the sync-back
    EXCLUDE_OPT="--exclude=${EXCLUDE_DIRS[*]}"
    [[ -n $BE_VERBOSE ]] && echo ">> EXCLUDE_OPT: ${EXCLUDE_OPT}"
fi

# finally do the actual sync forward
[[ -n $BE_VERBOSE ]] && echo ">> Synching ${SOURCE_DIR} ${TARGET_DIR}"
[[ -n $EXCLUDE ]] && echo ">> Excluding ${EXCLUDE_DIRS[*]}"

rsync \
    -az --delete \
    ${VERBOSE_OPT[@]} \
    ${DRYRUN_OPT[@]} \
    "${SOURCE_DIR}" "${TARGET_DIR}" \
    ${EXCLUDE_OPT[@]}

quit 0
