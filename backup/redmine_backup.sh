#!/bin/bash
# Redmine Backup script
# an improved and customisable script
# taken from http://www.redmine.org
#
# This code works only on Bash > 3.0
# This code is provided 'as-is'
# and released under the GPLv2

VERSION="0.1"
REDMINE_HOME="/usr/share/redmine"
DB_CONFIG="${REDMINE_HOME}/config/database.yml"
FILES="${REDMINE_HOME}/files"
NO_ARGS=0
E_OPTERROR=85
E_GENERROR=25
COMMIT_MSG=`date +%F-%H-%M`
GIT_SERVER=`git config remote.origin.url`

function usage() {
echo -e "Usage: `basename $0` [ -v | -r | -h ] [commit msg]

When called without parameters, the Redmine database and files are 
dumped to git-repo in ${REDMINE_HOME}, then the git-repo is pushed
to ${GIT_SERVER}.

When the first parameter is none of the ones below, the same backup
procedure is done, but the commit message is the parameter list 
instead of the date.

\t-v: be verbose
\t-r: Beforehand, check out the desired version of the Redmine database
\t\tfrom git-repo.
\t\tThis command will restore that version into Redmine.
\t-h: Print this help text.
\n"
}

function version() {
    echo -e "`basename $0` - Redmine Backup - version $VERSION\n"
}

function error() {
    verion
    echo -e "Wrong parameters passed: $1\n"
    usage
}

# The expected flags are
#  h v r
while getopts ":hvrn" Option
do
    case $Option in
        h ) version
            usage
            exit 0;;
        v ) BE_VERBOSE=true;;
        r ) DO_RESTORE=true;;
        n ) DRY_RUN=true;;
    esac
done

#  Decrements the argument pointer so it points to next argument.
#  $1 now references the first non-option item supplied on the command-line
#+ if one exists.
shift $(($OPTIND - 1))

# initialise the basic vars
if [ ! -d "${REDMINE_HOME}" ]
then
    echo "${REDMINE_HOME} not found, are you in the right server?"
    exit $E_GENERROR
fi
if [ ! -e "${DB_CONFIG}" ]
then
    echo "${DB_CONFIG} not found, check carefully."
    exit $E_GENERROR
fi
# here we are just guessing production will be 
# at the very beginning of the file
DATABASE=`cat ${DB_CONFIG} | sed -rn 's/ *database: (.+)/\1/p' | head -n 1`
USERNAME=`cat ${DB_CONFIG} | sed -rn 's/ *username: (.+)/\1/p' | head -n 1`
PASSWORD=`cat ${DB_CONFIG} | sed -rn 's/ *password: (.+)/\1/p' | head -n 1`

if [ $BE_VERBOSE ] 
then
    echo ">> database: $DATABASE"
    echo ">> username: $USERNAME"
    echo ">> password: $PASSWORD"
fi

cd "${REDMINE_HOME}"

# checking files directory
if [[ "$FILES" =~ "$REDMINE_HOME" ]]
then
    [ $BE_VERBOSE ] && echo ">> $FILES are in the same subdir"
    FILES_BACKUP="$FILES";
else
    [ $BE_VERBOSE ] && echo ">> $FILES are outside the home, moving everything in a subdir"
    if [ ! -d "${REDMINE_HOME}/files" ]
    then
        [ $BE_VERBOSE ] && echo ">> about to create ${REDMINE_HOME}/files"
        if [ $DRY_RUN ]
        then
            echo "mkdir ${REDMINE_HOME}/files"
        else
            mkdir ${REDMINE_HOME}/files
        fi
        FILES_BACKUP="$FILES"
    else
        [ $BE_VERBOSE ] && echo ">> ${REDMINE_HOME}/files exists, creating a different dir"
        if [ $DRY_RUN ]
        then
            echo "mkdir ${REDMINE_HOME}/backup_files"
        else
            mkdir ${REDMINE_HOME}/backup_files
        fi
        FILES_BACKUP="${REDMINE_HOME}/backup_files"
    fi
fi

# Restore
if [ $DO_RESTORE ]
then
    [ $BE_VERBOSE ] && echo ">> Restoring from $DATABASE";
    if [ $DRY_RUN ] 
    then
        echo "/usr/bin/mysql --user=${USERNAME} --password=${PASSWORD} $DATABASE < redmine.sql";
    else
        /usr/bin/mysql --user=${USERNAME} --password=${PASSWORD} $DATABASE < redmine.sql
    fi
    cp -f [!r][!e][!d][!m][!i][!n][!e]* $FILES

# Backup
else
    if [ $BE_VERBOSE ]; then echo ">> Backing up $DATABASE"; fi
    if [ "$1" ]; then COMMIT_MSG="$@"; fi
    if [ $DRY_RUN ]
    then
        echo "/usr/bin/mysqldump --user=${USERNAME} --password=${PASSWORD} --skip-extended-insert $DATABASE > redmine.sql"
    else
        /usr/bin/mysqldump --user=${USERNAME} --password=${PASSWORD} --skip-extended-insert $DATABASE > redmine.sql
    fi

    if [ "$FILES" != "$FILES_BACKUP" ]
    then
        [ $BE_VERBOSE ] && echo ">> Backing up files from ${FILES_BACKUP}";
        if [ $DRY_RUN ]
        then
            echo "cp -f ${FILES_BACKUP}/* ."
        else
            cp -f ${FILES_BACKUP}/* .
        fi
    fi

    [ $BE_VERBOSE ] && echo ">> adding and COMMITing on GIT"
    if [ $DRY_RUN ]
    then
        echo "git add *"
        echo "git commit -m $COMMIT_MSG"
        echo "git push --all origin"
    else
        git add *
        git commit -m "$COMMIT_MSG"
        git push --all origin
    fi
fi

# something has gone bad, we have to report it
if [ $? -ne 0 ]
then
    echo "Whoops! Something went wrong!"
    exit $E_GENERROR
fi

exit
