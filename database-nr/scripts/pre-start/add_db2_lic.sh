set -x
DIR="$(cd "$(dirname "$0")" && pwd -P)"
DB2LICM=~/sqllib/adm/db2licm
VR="$(source ~/sqllib/.instuse && printf "${V?}.${R?}")"
DB2LICD="${DIR?}/lic/${VR?}"

[ -d "${DB2LICD?}" ] && find "${DB2LICD?}" -name 'db2*.lic' -exec "${DB2LICM?}" -a "{}" \;
"${DB2LICM?}" -l
