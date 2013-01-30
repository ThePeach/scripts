#!/bin/bash
[[ $# -eq 0 ]] && exit 1
HOSTNAME=$1
BASE="/var/www/vhosts/${HOSTNAME}"

if [[ -e ${BASE}/httpdocs/sites/${HOSTNAME} ]]; then
    echo ">> adjusting symlink to files"
    # remove any non symlink file
    [[ ! -h ${BASE}/httpdocs/sites/${HOSTNAME}/files ]] && rm -rf ${BASE}/httpdocs/sites/${HOSTNAME}/files
    # create the symlink to files
    [[ -e ${BASE}/httpdocs/sites/default/files ]] && ln -sfn ${BASE}/httpdocs/sites/default/files ${BASE}/httpdocs/sites/${HOSTNAME}/files && echo '>> link to files created'
fi

exit 0
