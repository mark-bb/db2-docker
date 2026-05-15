#!/bin/bash
#
# FUNCTION: Starts up the container
#

function fix_problems() {
  # fixing various places...
  set -x
  MYHOST="$(cat /proc/sys/kernel/hostname)"
  chmod u+w "${DB2_HOME?}/db2nodes.cfg"
  echo "0 ${MYHOST?} 0" > "${DB2_HOME?}/db2nodes.cfg"
  [ -z "$(db2set DB2COMM | head -n1)" ] && db2set DB2COMM=TCPIP
  sudo /usr/bin/chown ${DB2INSTANCE?} ${DB2_HOME}/global.reg

  db2set DB2SYSTEM=${MYHOST?}

  [ -f "${DB2_HOME?}/.ftok" ] && { rm -f ${DB2_HOME?}/.ftok; ${DB2_HOME?}/bin/db2ftok; }
}

function exec_scripts() {
  set -x
  local d="${1?"Some directory must be provided"}"
  [ -d "${d?}" ] || return 1
  for s in $(ls "${d?}/"); do fs="${d?}/${s?}"; [ -f "${fs?}" -a -x "${fs?}" ] && ${fs?}; done
}

function on_stop() {
  set -x
  db2stop force
}


########
# MAIN
########

set -x
DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "${DIR?}/utils.sh"
[ ! -d "${DB2_HOME?}" -a ! -d "${INSTDIR?}" ] && { printf "DB2 installation image is not available in ${INSTDIR} and DB2 instance is not created. Can't proceed...\n" >&2; exit 1; }

vrmf_distr="$(grep '^vrmf' "${INSTDIR?}/db2/spec" | cut -d'=' -f2)"
[ -d "${DB2_HOME?}" ] && vrmf_users=$(source "${DB2_HOME?}/.instuse" && printf "${V?}.${R?}.${M?}.${F?}") || vrmf_users=""
vr_distr=$(printf "${vrmf_distr?}" | awk -v FS='.' '{print $1"."$2'})
vr_users=$(printf "${vrmf_users?}" | awk -v FS='.' '{print $1"."$2'})

sudo "${DIR?}/config.sh"

if [ "X${vrmf_distr?}" != "X" ]; then
if [ "X${vrmf_users?}" == "X" -o "X${vr_distr?}" != "X${vr_users?}" ]; then
  echo "Major upgrade or Install New"
  "${INSTDIR}/db2setup" -r ${RSPF?} -f sysreq
elif [ "X${vrmf_distr?}" != "X${vrmf_users?}" ]; then
  echo "FixPack update"
  "${INSTDIR}/installFixPack" -f db2lib -f sysreq -b "${DB2_HOME}" -y
fi
fi

set +x
. "${DB2_HOME?}/db2profile"
set -x

fix_problems
rfetmpf="/tmp/db2rfe.cfg"
sed \
  -e "s/{{ DB2INSTANCE }}/${DB2INSTANCE?}/g" \
  -e "s/{{ DB2PORT }}/${DB2PORT?}/g" \
  "${RFEF?}" | tee "${rfetmpf?}"
sudo "${DB2_HOME}/instance/db2rfe" -f "${rfetmpf?}"
rm -f "${rfetmpf?}"
fix_problems

if [ "X${vrmf_users?}" == "X" ]; then
  # New installation
  "${DIR?}/update_cfg.sh"
fi

if [ "X${TO_START_INSTANCE}" != "Xfalse" ]; then
  exec_scripts "${PRE_START_SCRIPT_DIR?}"
  db2start
  # DB2 CLP throws DB21018E, if we call it here directly...
  "${DIR?}/update_upgrade.sh" "${vrmf_distr?}" "${vrmf_users?}"
  "${DIR?}/activate_local_dbs.sh"
  exec_scripts "${POST_START_SCRIPT_DIR?}"
fi

trap on_stop SIGTERM

db2diag -readfile -f &
wait
