#!/bin/bash
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

VERSION='0.1'
DATE=`date "+%Y-%m-%dT%H_%M_%S"`
HOME="/home/`whoami`/"
NO_ARGS=0 
E_OPTERROR=85
E_GENERROR=25
EXCLUDE_OPT=''
REMOTE_OPT=''

function usage() {
    echo -e "Syntax: `basename $0` [-v|-h|-r <[user@]host>|-e <exclude list>] [<source>] <dest>
\t-v: be verbose
\t-h: shows this help
\t-r <[user@]host>: will send the data via ssh to the remote host using
\t\tusing the user if any have been specified
\t-e <exclude list>: the exclude list, see rsync manual on how to create it
\t\tby default it will backup everything (normally not something you want)
\t-n: do a dry run, don't actually start anything 
\t\tjust check things are ready togo
\t<source>: specify the path to the source directory to backup
\t\twill use /home/`whoami`/ if not specified
\t<dest>: the destination directory, if not existing it'll be created.
\n"
}

function version() {
    echo -e "`basename $0` - Time R-Machine - version $VERSION\n"
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
while getopts ":hvnr:e:" Option
do
    case $Option in
        h ) version
            usage
            exit 0;;
        v ) BE_VERBOSE=true;;
        n ) DRYRUN_OPT=("-n");;
        r ) REMOTE_OPT=$OPTARG;;
        e ) [ ! -e $OPTARG ] && error "$OPTARG not accessible" && exit $E_OPTERROR
            EXCLUDE_OPT=("--delete-excluded --exclude-from=$OPTARG");;
    esac
done

#  Decrements the argument pointer so it points to next argument.
#  $1 now references the first non-option item supplied on the command-line
#+ if one exists.
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

# checking the destination directory is fine
# TODO: should be checking if the destination dir exists also for remote hosts
# TODO: should check permissions are write enabled for the user
if [ ! -e "$DEST" ]
then
    echo "$DEST not found, creating it"
    mkdir "$DEST"
    if [ "$?" -ne 0 ]
    then
        echo "Error while creating the directory $DEST
check your permissions"
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
I think you might be ready to go now."
fi

MV_CMD="mv $DEST/incomplete_back-$DATE $DEST/back-$DATE"
LN_CMD="ln -sfn back-$DATE current"

rsync \
    -az --progress --partial \
    --delete \
    ${DRYRUN_OPT[@]} \
    ${EXCLUDE_OPT[@]} \
    --link-dest=$DEST/current \
    $SOURCE $DEST/incomplete_back-$DATE

if [ $? -ne 0 ]
then
    echo "Rsync failed miserably, I've kept the partial backup in
$DEST/incomplete_back-$DATE
feel free to remove it when everything's been verified.

Aborting now."
    exit $E_GENERROR
elif [ -n "$DRYRUN_OPT" ]
then
    exit
fi

if [ "$REMOTE_OPT" != "" ]
then
    [ -n $BE_VERBOSE ] && echo "ssh \"$REMOTE_OPT \"$MV_CMD && $LN_CMD\""
    ssh $REMOTE_OPT "$MV_CMD && $LN_CMD"
else
    [ -n $BE_VERBOSE ] && echo "$MV_CMD && $LN_CMD"
    cd $DEST
    $MV_CMD && $LN_CMD
fi

# something has gone bad, we have to report it
if [ $? -ne 0 ]
then
   echo "Whoops! Something went wrong!"
   exit $E_GENERROR
fi

exit

