#!/bin/bash
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
\t\t excluded. See man rsync under INCLUDE/EXCLUDE PATTERN RULES on how to write them.
\t-b <BACKUP_DIR>: the backup directory where the to put the backup in tar.bz2 format
\t\t of the whole TARGET_DIR before doing any synchronisation.
\t-u <WEB_USER>: the user to use in order to fix the permissions, usually the 
\t\t server administrator. Permissions will be set as ug+rwX recursivly
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
while getopts ":hnve:b:u:" Option
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
        u ) WEB_USER=$OPTARG;;
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

# BACKUP
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

    
# Do some prep-work on the directories to exclude
if [ -n $EXCLUDE ]; then
    read -ar EXCLUDE_DIRS <<< "$EXCLUDE_DIRS"
    i=1
    for dir in $EXCLUDE_DIRS
    do
        if [[ $i -eq  1 ]]; then
            EXCLUDE_OPT="--exclude=${dir}"
        else
            EXCLUDE_OPT="${EXCLUDE_OPT},--exclude=${dir}"
        fi
        i=$(( $i + 1 ))
    done
    # if we are here we can start doing the sync-back
    read -ar EXCLUDE_OPT <<< "$EXCLUDE_OPT"
fi

IFS=','

# finally do the actual sync forward
[[ -n $BE_VERBOSE ]] && echo ">> Synching ${SOURCE_DIR} ${TARGET_DIR}"
[[ -n $EXCLUDE ]] && [[ -n $BE_VERBOSE ]] && echo ">> EXCLUDE_OPT: ${EXCLUDE_OPT[@]}"

    
# rsync options "rlptDz" excluding owner and group changes

rsync \
    -rlptDz --delete \
    ${VERBOSE_OPT[@]} \
    ${DRYRUN_OPT[@]} \
    ${EXCLUDE_OPT[@]} \
    "${SOURCE_DIR}" "${TARGET_DIR}"

# TODO check no errors during rsync, bail out and return the error?

if [[ -n $WEB_USER ]]; then
    # set owner:group to $WEB_USER:$WEB_USER 
    [[ -n $BE_VERBOSE ]] && echo ">> Updating owner:group to ${WEB_USER}:${WEB_USER}"
    if [[ -n $DRYRUN_OPT ]]; then
        echo chown -R $WEB_USER:$WEB_USER "${TARGET_DIR}"
    else
        chown -R $WEB_USER:$WEB_USER "${TARGET_DIR}"
    fi

    # set permissions to ug+rwX
    [[ -n $BE_VERBOSE ]] && echo ">> Updating permissions to ug+rwX,o-rwx"
    if [[ -n $DRYRUN_OPT ]]; then
        echo chmod -R ug+rwX,o-rwx "${TARGET_DIR}"
    else
        chmod -R ug+rwX,o-rwx "${TARGET_DIR}"
    fi
fi

# TODO check no errors during rsync, bail out and return the error?

quit 0
