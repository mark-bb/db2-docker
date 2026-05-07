#!/bin/bash
#

set -x
if command -v postfix &>/dev/null; then
  newaliases
  postfix start
fi
