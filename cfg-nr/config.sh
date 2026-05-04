#!/bin/bash
# 
# FUNCTION: sudo commands to config non-root installation
#
set -x
DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "${DIR?}/utils.sh"

[ -d "${CONFDIR?}" ] || mkdir -p "${CONFDIR?}"
if [ ! -d "${USERHOME?}/sqllib" ]; then
  cp /etc/skel/.[a-z]* "${USERHOME?}/"
  chown -R ${DB2INSTANCE?}:$(id -g ${DB2INSTANCE?}) "${USERHOME?}"
  chmod 700 "${USERHOME?}"
fi
echo "${DB2INSTANCE?}:${DB2INST1_PASSWORD?}" | chpasswd

[ -d "${DATADIR?}" ] || mkdir -p "${DATADIR?}"
[ -d "${DATADIR?}/${DB2INSTANCE?}" ] || install -m 775 -o ${DB2INSTANCE?} -g $(id -g ${DB2INSTANCE?}) -d "${DATADIR?}/${DB2INSTANCE?}"
/setup/add_users_n_groups.sh
