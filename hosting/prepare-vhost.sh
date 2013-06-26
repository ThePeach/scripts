#!/bin/bash
[[ $# -eq 0 ]] && exit 1
HOSTNAME=$1
BASE="/var/www/vhosts/${HOSTNAME}"
TEMP="${BASE}/temp"
USER="jenkins"

if [[ -e $BASE ]]; then
	if [[ ! -e $TEMP ]]; then
		echo ">> ${TEMP} not existing, exiting"
		exit 1
	fi
	echo -e ">> changing owner of
\t${BASE}
\t${TEMP}
   to ${USER}"
	chown $USER $BASE
	chown $USER $TEMP
	echo ">> cleaning ${TEMP}"
	rm -vrf ${TEMP}/.[^.] ${TEMP}/.??*
fi
