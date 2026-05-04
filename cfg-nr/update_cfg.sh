#!/bin/bash
#
# FUNCTION: Update DB2 config on fresh installaion
#
DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "${DIR?}/utils.sh"
set -x
db2 "update dbm cfg using DFTDBPATH ${DATADIR?}"
