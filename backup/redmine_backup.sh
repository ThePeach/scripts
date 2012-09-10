#!/bin/bash
# Redmine Backup script
# an improved and customisable script
# taken from http://www.redmine.org
#
# This code is provided 'as-is'
# and released under the GPLv2

VERSION="0.1"
REDMINE_HOME="/usr/share/redmine/"
DB_CONFIG="${REDMINE_HOME}default/database.yml"
FILES="/var/lib/redmine/default/files"
NO_ARGS=0
E_OPTERROR=85
E_GENERROR=25
COMMITT_MSG=`date +%F-%H-%M`
GIT_SERVER=`git config remote.origin.url`

function usage() {
echo -e "Usage: `basename $2` [ -v | -r | -h ] [commit msg]

When called without parameters, the Redmine database and files are dumped to
git-repo in ${REDMINE_HOME}, then the git-repo is pushed to ${GIT_SERVER}.

When the first parameter is none of the ones below, the same backup procedure
is done, but the commit message is the parameter list instead of the date.

\t-v: be verbose
\t-r: Beforehand, check out the desired version of the Redmine database from 
\t\tgit-repo. This command will restore that version into Redmine.
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
while getopts ":hvr:" Option
do
    case $Option in
        h ) version
            usage
            exit 0;;
        v ) BE_VERBOSE=true;;
        r ) DO_RESTORE=true;;
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
DATABASE=`cat ${DB_CONFIG} | sed -rn 's/ *database: (.+)/\1/p'`
USERNAME=`cat ${DB_CONFIG} | sed -rn 's/ *username: (.+)/\1/p'`
PASSWORD=`cat ${DB_CONFIG} | sed -rn 's/ *password: (.+)/\1/p'`

if [ -n $BE_VERBOSE ] 
then
    echo "database: $DATABASE"
    echo "username: $USERNAME"
    echo "password: $PASSWORD"
fi

cd "${REDMINE_HOME}"

# Restore
if [ $DO_RESTORE ]
then
  /usr/bin/mysql --user=${USERNAME} --password=${PASSWORD} $DATABASE < redmine.sql
  cp -f [!r][!e][!d][!m][!i][!n][!e]* $FILES

# Backup
else
  if [ "$1" ]; then COMMITT_MSG="$@";
  /usr/bin/mysqldump --user=${USERNAME} --password=${PASSWORD} --skip-extended-insert $DATABASE > redmine.sql
  cp -f ${FILES}/* .
  git add *
  git commit -m "$MSG" 
  git push --all origin
fi

# something has gone bad, we have to report it
if [ $? -ne 0 ]
then
   echo "Whoops! Something went wrong!"
   exit $E_GENERROR
fi

exit
