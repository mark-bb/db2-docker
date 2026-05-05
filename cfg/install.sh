#!/bin/bash
#
# FUNCTION: install the software
#

set -x
VRMF=${1?"db2 version in the v.r.m.f format must be specified as a parameter"}
DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "${DIR?}/utils.sh"

if command -v apt-get &>/dev/null; then
  dpkg --add-architecture i386
  apt-get update
  if apt-cache policy libaio1t64 | grep '^libaio1t64' &>/dev/null; then libaio=libaio1t64; else libaio=libaio1; fi
  DEBIAN_FRONTEND=noninteractive apt-get install ksh binutils file ${libaio?} libcurl4 libnuma1 libxml2 libpam0g:i386 libstdc++6:i386 -y
  apt-get clean
  if [ "${libaio?}" = "libaio1t64" ]; then
    # DB2 may not start without this link
    libdir="/usr/lib/$(uname -m)-linux-gnu"
    [ -f "${libdir?}/libaio.so.1t64" -a ! -f "${libdir?}/libaio.so.1" ] && ln -sr "${libdir?}/libaio.so.1t64" "${libdir?}/libaio.so.1"
  fi
elif command -v dnf &>/dev/null; then
  dnf install binutils file libaio numactl-libs libxcrypt-compat pam.i686 libstdc++.i686 -y
  dnf clean all
elif command -v zypper &>/dev/null; then
  zypper addrepo -f http://download.opensuse.org/distribution/leap/15.6/repo/oss/ leap-oss
  zypper --gpg-auto-import-keys in -y awk sudo libnuma1 libaio1 net-tools-deprecated binutils pam-32bit libstdc++6-32bit
  zypper clean --all

  groupadd -g 8 mail
  useradd -d /var/spool/mail -s /usr/sbin/nologin -g mail -u 8 mail
  chown root:mail /var/spool/mail

  groupadd -g 2 bin
  useradd -d /bin -s /usr/sbin/nologin -g bin -u 2 bin
else
  echo "Unknown package manager" >&2
  exit 1
fi

touch /etc/services
for id in ${DB2INSTANCE_UID?} ${DB2FUSER_UID?}; do
  u=$(getent passwd ${id?} 2>/dev/null) && userdel -r ${u%%:*}
done
for id in ${DB2IGROUP_GID?} ${DB2FGROUP_GID?}; do
  g=$(getent group  ${id?} 2>/dev/null) && groupdel   ${g%%:*}
done

"${INSTDIR?}/db2prereqcheck" -i -s -l
VR="$(printf "${VRMF?}" | awk -F'.' '{print $1"."$2}')"
sed -i "s/{{ VR }}/${VR?}/" "${RSPF?}"
"${INSTDIR?}/db2setup" -r "${RSPF?}" -f sysreq
