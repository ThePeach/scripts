#!/bin/bash
usage() {
cat <<EOF
Usage: redmine_bak [ -r | -h ] [commit msg]

When called without parameters, the Redmine database and files are dumped to
git-repo in /root/redmine, then the git-repo is pushed to ssh://git@GitServer.

When the first parameter is none of the ones below, the same backup procedure
is done, but the commit message is the parameter list instead of the date.

-r --restore
Beforehand, check out the desired version of the Redmine database from git-repo.
This command will restore that version into Redmine.

-h --help
Print this help text.
EOF
exit $1
}

REDMINE_HOME="/usr/share/redmine/"

DATABASE=`cat ${REDMINE_HOME}default/database.yml | sed -rn 's/ *database: (.+)/\1/p'`
USERNAME=`cat /etc/redmine/default/database.yml | sed -rn 's/ *username: (.+)/\1/p'`
PASSWORD=`cat /etc/redmine/default/database.yml | sed -rn 's/ *password: (.+)/\1/p'`
FILES=/var/lib/redmine/default/files
cd /root/redmine

# Help
if [ "$1" = "-h" -o "$1" = "--help" ]; then
  usage 0

# Restore
elif [ "$1" = "-r" -o "$1" = "--restore" ]; then
  /usr/bin/mysql --user=${USERNAME} --password=${PASSWORD} $DATABASE < redmine.sql
  cp -f [!r][!e][!d][!m][!i][!n][!e]* $FILES

# Backup
else
  if [ "$1" ]; then MSG="$@"; else MSG="`date`"; fi
  /usr/bin/mysqldump --user=${USERNAME} --password=${PASSWORD} --skip-extended-insert $DATABASE > redmine.sql
  cp -f ${FILES}/* .
  git add *
  git commit -m "$MSG" 
  git push --all origin

fi
