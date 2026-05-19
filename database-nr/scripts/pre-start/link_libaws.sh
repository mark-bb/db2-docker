#!/bin/bash

set -x
. /setup/utils.sh

if command -v apt-get &>/dev/null; then
  OS=UBUNTU
  RELEASE="$(sed -n 's/DISTRIB_RELEASE=\([0-9]\+\).*/\1/p' /etc/lsb-release)"
elif command -v dnf &>/dev/null || command -v yum &>/dev/null; then
  OS=RHEL
  RELEASE="$(sed -n 's/.* release \([0-9]\+\).*/\1/p' /etc/redhat-release)"
elif command -v zypper &>/dev/null; then
  OS=SLES
  RELEASE="$(sed -n 's/^VERSION_ID="\([0-9]\+\).*/\1/p' /etc/os-release)"
fi

cnt=0
dir=""
while [ ${cnt?} -lt 3 ]; do
  dir="$(find "${DB2_HOME?}/lib64/awssdk/${OS?}/" -type d -name "$((RELEASE-cnt)).*")"
  [ -n "${dir?}" ] && break
  ((cnt+=1))
done

rm -f "${DB2_HOME?}"/lib64/libaws*
if [ -n "${dir?}" ]; then
  ln -sr "${dir?}"/libaws* "${DB2_HOME?}"/lib64/
  ls -l "${DB2_HOME?}"/lib64/libaws*
fi
