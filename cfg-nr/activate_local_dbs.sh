#!/bin/bash
#
# Function: Activates all local databases
#

DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "${DIR?}/utils.sh"

set -x
for db in $(list_local_dbs); do
  db2 activate db ${db?}
done
