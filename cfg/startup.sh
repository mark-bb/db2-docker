#!/bin/bash
#
# Function: setup a container
#

function users_n_directories() {
  set -x

  getent group ${DB2IGROUP?} &>/dev/null || groupadd -g ${DB2IGROUP_GID?} ${DB2IGROUP?}
  getent group ${DB2FGROUP?} &>/dev/null || groupadd -g ${DB2FGROUP_GID?} ${DB2FGROUP?}

  [ ! -d "${CONFDIR?}" ] && mkdir -p "${CONFDIR?}"
  getent passwd ${DB2INSTANCE?} &>/dev/null || useradd -m -b ${CONFDIR?} -s /bin/bash -u ${DB2INSTANCE_UID?} -g ${DB2IGROUP?} ${DB2INSTANCE?}
  getent passwd ${DB2FUSER?}    &>/dev/null || useradd -m -b ${CONFDIR?} -s /bin/bash -u ${DB2FUSER_UID?}    -g ${DB2FGROUP?} ${DB2FUSER?}

  printf "${DB2INSTANCE?}:${DB2INST1_PASSWORD?}" | chpasswd

  [ ! -d "${DATADIR?}" ] && mkdir -p "${DATADIR?}"
  [ ! -d "${DATADIR?}/${DB2INSTANCE?}" ] && install -m 775 -o ${DB2INSTANCE?} -g $(id -g ${DB2INSTANCE?}) -d "${DATADIR?}/${DB2INSTANCE?}"
  /setup/add_users_n_groups.sh
}

function fix_files() {
  # fixing files...
  set -x
  MYHOST="$(cat /proc/sys/kernel/hostname)"
  "${DB2PATH?}/instance/db2iset" -g DB2SYSTEM=${MYHOST?}
  "${DB2PATH?}/bin/db2greg" -getinstrec instancename=${DB2INSTANCE?} | grep InstanceName &>/dev/null \
	  || "${DB2PATH?}/bin/db2greg" -addinstrec service=DB2,instancename=${DB2INSTANCE?}
  echo "0 ${MYHOST?} 0" > "${DB2_HOME?}/db2nodes.cfg"

  if ! grep -E "[^0-9]${DB2PORT?}/tcp" /etc/services &>/dev/null; then
	cat <<-EOF | tee -a /etc/services
	db2c_${DB2INSTANCE?}      ${DB2PORT?}/tcp
	DB2_${DB2INSTANCE?}       60000/tcp
	DB2_${DB2INSTANCE?}_END   60000/tcp
	EOF
  fi
}

function fix_problems() {
  # fixing various places...
  fix_files

  f="${DB2_HOME?}/adm/fencedid"
  [ "$(ls -l "${f?}" | awk '{print $4}')" != "${DB2IGROUP?}" ] && chgrp ${DB2IGROUP?} "${f?}"

  [ -f "${DB2_HOME?}/.ftok" ] && su - ${DB2INSTANCE?} -c 'rm -f sqllib/.ftok ; sqllib/bin/db2ftok'
  
  # Sometimes the db2 upgrade cleans them out due to unknown reason
  kv_str="SVCENAME:db2c_${DB2INSTANCE?} SYSADM_GROUP:${DB2IGROUP?}"
  IFS=' ' read -r -a kv  <<< "${kv_str?}"
  for x in "${!kv[@]}"; do
    parm=${kv[x]%:*}
    val_need=${kv[x]#*:}
    val_curr="$(su - ${DB2INSTANCE?} -c "db2 get dbm cfg | grep -F '(${parm?})'" | awk -v FS='= ' '{print $2}')"
    [ "X${val_curr?}" = "X" ] && su - ${DB2INSTANCE?} -c "db2 update dbm cfg using ${parm?} ${val_need?}"
  done
}

function update_upgrade() {
  # If really needed only
  set -x
  if [ "X${vrmf_users?}" != "X" ]; then
    if  [ "${vr_distr?}" != "${vr_users?}" ]; then
      # Upgrade all local databases
      for db in $(list_local_dbs); do
        su - ${DB2INSTANCE?} -c "db2 upgrade database ${db?}"
      done
    elif  [ "${vrmf_distr?}" != "${vrmf_users?}" ]; then
      # Update all local databases
      DB2UPDV="$(find "${DB2PATH?}/bin" -name 'db2updv*')"
      for db in $(list_local_dbs); do
        su - ${DB2INSTANCE?} -c "set -x;
          ${DB2UPDV?} -d ${db?} ;
          db2 connect to ${db?} ;
          db2 BIND '${DB2_HOME?}/bnd/db2schema.bnd' BLOCKING ALL GRANT PUBLIC SQLERROR CONTINUE ;
          db2 BIND '${DB2_HOME?}/bnd/@db2ubind.lst' BLOCKING ALL GRANT PUBLIC ACTION ADD ;
          db2 BIND '${DB2_HOME?}/bnd/@db2cli.lst' BLOCKING ALL GRANT PUBLIC ACTION ADD ;
          db2 terminate ; "
      done
    fi
  fi
}

function list_local_dbs() {
  su - ${DB2INSTANCE?} -c "db2 list db directory | awk -v RS='' '/= Indirect/' | awk -F'= ' '/Database alias/{print \$2}'"
}

function activate_local_dbs() {
  # Activate all local databases
  set -x
  for db in $(list_local_dbs); do
    su - ${DB2INSTANCE?} -c "db2 activate db ${db?}"
  done
}

function exec_scripts() {
  set -x
  local d="${1?"Some directory must be provided"}"
  [ -d "${d?}" ] || return 1
  for s in $(ls "${d?}/"); do fs="${d?}/${s?}"; [ -f "${fs?}" -a -x "${fs?}" ] && ${fs?}; done
}

function on_stop() {
  set -x
  su - ${DB2INSTANCE?} -c "db2stop force"
}


########
# MAIN
########

set -x
DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "${DIR?}/utils.sh"
DB2LS_OUT="$(db2ls -c | tail -1)"
DB2PATH="$(printf "${DB2LS_OUT?}" | cut -d':' -f1)"

users_n_directories

vrmf_distr="$(printf "${DB2LS_OUT?}" | cut -d':' -f2)"
[ -d "${DB2_HOME?}" ] && vrmf_users=$(source "${DB2_HOME?}/.instuse" && printf "${V?}.${R?}.${M?}.${F?}") || vrmf_users=""
vr_distr=$(printf "${vrmf_distr?}" | awk -v FS='.' '{print $1"."$2'})
vr_users=$(printf "${vrmf_users?}" | awk -v FS='.' '{print $1"."$2'})

if [ "${vrmf_distr?}" != "${vrmf_users?}" ]; then
  fs_protected_regular=$(cat /proc/sys/fs/protected_regular)
  [ ${fs_protected_regular?} -ne 0 ] && { printf 0 > /proc/sys/fs/protected_regular; }
  [ -d "${DB2_HOME?}" ] && fix_files
  "${DB2PATH?}/instance/db2icrt" -update-instance-if-exists -p ${DB2PORT?} -u ${DB2FUSER?} ${DB2INSTANCE?}
  [ ${fs_protected_regular?} -ne 0 ] && { printf ${fs_protected_regular?} > /proc/sys/fs/protected_regular; }
fi

if [ "X${vrmf_users?}" = "X" ]; then
  # New installation
  su - ${DB2INSTANCE?} -c "db2 update dbm cfg using DFTDBPATH ${DATADIR?}"
fi

fix_problems

if [ "X${TO_START_INSTANCE}" != "Xfalse" ]; then
  exec_scripts "${PRE_START_SCRIPT_DIR?}"
  su - ${DB2INSTANCE?} -c "db2start"
  exec_scripts "${POST_START_SCRIPT_DIR?}"
  update_upgrade
  activate_local_dbs
fi

trap on_stop SIGTERM

su - ${DB2INSTANCE?} -c "db2diag -f" | tee &
wait
