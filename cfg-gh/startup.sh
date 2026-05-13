#!/bin/bash
#
# Function: setup a container
#

function on_stop() {
  set -x
  "${MAIN_DIR?}/bin/stop.sh"
}


########
# MAIN
########

set -x
SETUP_DIR="/opt/ibm"
MAIN_DIR="${SETUP_DIR?}/ibm-db2GeniusHub"
CRYPT="${MAIN_DIR?}/dsutil/bin/crypt.sh"
UC_SETUP_ADMIN_PASSWORD_ENC="$("${CRYPT?}" "${UC_SETUP_ADMIN_PASSWORD?}")"

[ -f "${MAIN_DIR?}/setup.conf.ORIG" ] || cp "${MAIN_DIR?}/setup.conf" "${MAIN_DIR?}/setup.conf.ORIG"

sed \
  -e "s/^#\?\(product\.license\.accepted\)=.*/\1=y/" \
  -e "s/^#\?\(port\)=.*/\1=${HTTP_PORT:-"11100"}/" \
  -e "s/^#\?\(https\.port\)=.*/\1=${HTTPS_PORT:-"11101"}/" \
  -e "s/^#\?\(uc_setup_admin\)=.*/\1=${UC_SETUP_ADMIN?}/" \
  -e "s/^#\?\(uc_setup_admin_password\)=.*/\1=${UC_SETUP_ADMIN_PASSWORD_ENC?}/" \
  "${MAIN_DIR?}/setup.conf.ORIG" | tee "${MAIN_DIR?}/setup.conf"

if [ "X${REPOSITORYDB_HOST}" != "X" ]; then
  REPOSITORYDB_PASSWORD_ENC="$("${CRYPT?}" "${REPOSITORYDB_PASSWORD?}")"
  sed -i \
    -e "s/^#\?\(repositoryDB\.host\)=.*/\1=${REPOSITORYDB_HOST?}/" \
    -e "s/^#\?\(repositoryDB\.port\)=.*/\1=${REPOSITORYDB_PORT?}/" \
    -e "s/^#\?\(repositoryDB\.databaseName\)=.*/\1=${REPOSITORYDB_DATABASENAME?}/" \
    -e "s/^#\?\(repositoryDB\.user\)=.*/\1=${REPOSITORYDB_USER?}/" \
    -e "s/^#\?\(repositoryDB\.password\)=.*/\1=${REPOSITORYDB_PASSWORD_ENC?}/" \
    "${MAIN_DIR?}/setup.conf"

  # Wait for REPODB
  JAVA="$(find "${MAIN_DIR?}" -type f -name 'java')"
  DB2JCC4="$(find "${MAIN_DIR?}" -type f -name 'db2jcc4-*.jar')"
  URL="jdbc:db2://${REPOSITORYDB_HOST?}:${REPOSITORYDB_PORT?}/${REPOSITORYDB_DATABASENAME?}"

  set -o pipefail
  while ! "${JAVA?}" \
    -cp "${DB2JCC4?}" \
    com.ibm.db2.jcc.DB2Jcc \
    -url "${URL?}" \
    -user "${REPOSITORYDB_USER?}" -password "${REPOSITORYDB_PASSWORD?}" \
    | grep -E '\[jcc\]|SQLCODE|SQLSTATE'; do
    printf "$(date +'%F-%T'): The database at this url is not accessible: ${URL?}\n\n"
    sleep 10
  done

fi

"${MAIN_DIR?}/setup.sh" -silent

trap on_stop SIGTERM

while :; do tail -f "${MAIN_DIR?}/logs/messages.log"; done &
wait
