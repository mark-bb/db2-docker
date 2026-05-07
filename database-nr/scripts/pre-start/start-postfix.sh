#!/bin/bash
#

set -x
if command -v postfix &>/dev/null; then
  sudo newaliases
  sudo postfix start
fi
