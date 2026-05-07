set -x
su - db2inst1 -c "db2licm -l"
libaio1="/usr/lib/x86_64-linux-gnu/libaio.so.1"
libaio1t64="/usr/lib/x86_64-linux-gnu/libaio.so.1t64"
if [ ! -f "${libaio1?}" -a -f "${libaio1t64?}" ]; then 
  ln -sr "${libaio1t64?}" "${libaio1?}"
fi
