#!/bin/bash
#
# FUNCTION: install the software
#

set -x

if command -v apt-get &>/dev/null; then
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install ksh binutils file postfix mailutils vim -y
  apt-get clean
elif command -v dnf &>/dev/null || command -v yum &>/dev/null; then
  command -v dnf &>/dev/null && mgr=dnf || mgr=yum
  ${mgr?} install binutils file postfix vim -y
  ${mgr?} install ksh -y
  ${mgr?} install mailx -y
  ${mgr?} clean all
elif command -v zypper &>/dev/null; then
  # zypper addrepo -f http://download.opensuse.org/distribution/leap/15.6/repo/oss/ leap-oss
  # zypper --gpg-auto-import-keys in -y awk sudo libnuma1 libaio1 net-tools-deprecated binutils postfix mailx vim pam-32bit libstdc++6-32bit
  zypper install -y awk binutils file gzip tar postfix mailx vim
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
