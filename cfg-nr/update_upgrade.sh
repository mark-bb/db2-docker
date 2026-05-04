#!/bin/bash
#
# Function: Update or Upgrade all local databases
#

DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "${DIR?}/utils.sh"

set -x
vrmf_distr=${1?}
vrmf_users=${2?}
vr_distr=$(printf "${vrmf_distr?}" | awk -v FS='.' '{print $1"."$2'})
vr_users=$(printf "${vrmf_users?}" | awk -v FS='.' '{print $1"."$2'})

# If really needed only
if [ "X${vrmf_users?}" != "X" -a "X${vrmf_distr?}" != "X" ]; then
    if  [ "${vr_distr?}" != "${vr_users?}" ]; then
      # Upgrade all local databases
      for db in $(list_local_dbs); do
        db2 upgrade database ${db?}
      done
    elif  [ "${vrmf_distr?}" != "${vrmf_users?}" ]; then
      # Update all local databases
      DB2UPDV="$(find "${DB2_HOME?}/bin" -name 'db2updv*')"
      for db in $(list_local_dbs); do
        { set -x;
          "${DB2UPDV?}" -d ${db?};
          db2 connect to ${db?};
          db2 "BIND '${DB2_HOME?}/bnd/db2schema.bnd' BLOCKING ALL GRANT PUBLIC SQLERROR CONTINUE";
          db2 "BIND '${DB2_HOME?}/bnd/@db2ubind.lst' BLOCKING ALL GRANT PUBLIC ACTION ADD";
          db2 "BIND '${DB2_HOME?}/bnd/@db2cli.lst' BLOCKING ALL GRANT PUBLIC ACTION ADD";
          db2 terminate; }
      done
    fi
fi
