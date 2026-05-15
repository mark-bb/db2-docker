#!/bin/bash
#

set -x
if command -v /usr/sbin/sshd &>/dev/null; then
  /usr/bin/ssh-keygen -A
  /usr/sbin/sshd
fi
