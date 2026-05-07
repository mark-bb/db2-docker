set -x
DIR="$(cd "$(dirname "$0")" && pwd -P)"
DB2LS_OUT="$(db2ls -c | tail -1)"
DB2PATH="$(printf "${DB2LS_OUT?}" | cut -d':' -f1)"
DB2LICM="${DB2PATH?}/adm/db2licm"
VR="$(printf "${DB2LS_OUT?}" | cut -d':' -f2 | awk -F'.' '{print $1"."$2}')"
DB2LICD="${DIR?}/lic/${VR?}"

[ -d "${DB2LICD?}" ] && find "${DB2LICD?}" -name 'db2*.lic' -exec "${DB2LICM?}" -a "{}" \;
"${DB2LICM?}" -l
