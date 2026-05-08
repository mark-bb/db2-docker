#!/bin/bash
#
# FUNCTION: install the software
#

set -x
DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "${DIR?}/utils.sh"

if command -v apt-get &>/dev/null; then
  dpkg --add-architecture i386
  apt-get update
  if apt-cache policy libaio1t64 | grep '^libaio1t64' &>/dev/null; then libaio=libaio1t64; else libaio=libaio1; fi
  DEBIAN_FRONTEND=noninteractive apt-get install ksh sudo binutils file ${libaio?} libcurl4 libnuma1 libxml2 postfix mailutils vim libpam0g:i386 libstdc++6:i386 -y
  apt-get clean
  if [ "${libaio?}" = "libaio1t64" ]; then
    # DB2 may not start without this link
    libdir="/usr/lib/$(uname -m)-linux-gnu"
    [ -f "${libdir?}/libaio.so.1t64" -a ! -f "${libdir?}/libaio.so.1" ] && ln -sr "${libdir?}/libaio.so.1t64" "${libdir?}/libaio.so.1"
  fi
elif command -v dnf &>/dev/null || command -v yum &>/dev/null; then
  command -v dnf &>/dev/null && mgr=dnf || mgr=yum
  ${mgr?} install sudo binutils file libaio numactl-libs libxcrypt-compat postfix vim -y
  ${mgr?} install pam.i686 libstdc++.i686 -y
  ${mgr?} install ksh -y
  ${mgr?} install mailx -y
  ${mgr?} clean all
elif command -v zypper &>/dev/null; then
  # zypper addrepo -f http://download.opensuse.org/distribution/leap/15.6/repo/oss/ leap-oss
  # zypper --gpg-auto-import-keys in -y awk sudo libnuma1 libaio1 net-tools-deprecated binutils postfix mailx vim pam-32bit libstdc++6-32bit
  zypper install -y awk sudo libnuma1 libaio1 net-tools-deprecated binutils file gzip tar postfix mailx vim
  zypper clean --all

  if ! getent passwd mail &>/dev/null; then
    groupadd -g 8 mail
    useradd -d /var/spool/mail -s /usr/sbin/nologin -g mail -u 8 mail
    chown root:mail /var/spool/mail
  fi

  if ! getent passwd bin &>/dev/null; then
    groupadd -g 2 bin
    useradd -d /bin -s /usr/sbin/nologin -g bin -u 2 bin
  fi
else
  echo "Unknown package manager" >&2
  exit 1
fi

touch /etc/services
sed -i "/[\t ]${DB2PORT?}\//d" /etc/services
u=$(getent passwd ${DB2INSTANCE_UID?} 2>/dev/null) && userdel -r ${u%%:*}
g=$(getent group  ${DB2IGROUP_GID?}   2>/dev/null) && groupdel   ${g%%:*}

groupadd -g ${DB2IGROUP_GID?} ${DB2IGROUP?}
mkdir -p "${CONFDIR?}"
useradd -m -d ${USERHOME?} -s /bin/bash -u ${DB2INSTANCE_UID?} -g ${DB2IGROUP?} ${DB2INSTANCE?}

# install -m 750 -o root -g root -d /etc/sudoers.d
cat <<EOF | tee /etc/sudoers.d/${DB2INSTANCE?}
Defaults env_keep += "DB2INST1_PASSWORD ADDUSERS ADDGROUPS"
${DB2INSTANCE?} ALL=(ALL) NOPASSWD: /setup/config.sh
${DB2INSTANCE?} ALL=(ALL) NOPASSWD: /setup/add_users_n_groups.sh
${DB2INSTANCE?} ALL=(ALL) NOPASSWD: ${DB2_HOME?}/instance/db2rfe *
${DB2INSTANCE?} ALL=(ALL) NOPASSWD: /usr/bin/chown ${DB2INSTANCE?} ${DB2_HOME?}/global.reg
${DB2INSTANCE?} ALL=(ALL) NOPASSWD: /usr/bin/newaliases
${DB2INSTANCE?} ALL=(ALL) NOPASSWD: /usr/sbin/postfix *
EOF
