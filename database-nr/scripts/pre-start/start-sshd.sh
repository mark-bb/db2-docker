#!/bin/bash
#

set -x
if command -v /usr/sbin/sshd &>/dev/null; then
  sudo /usr/bin/ssh-keygen -A
  sudo /usr/sbin/sshd
fi
