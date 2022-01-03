#!/usr/bin/env ash
# shellcheck shell=dash

set -exuo pipefail

# shellcheck source=/dev/null
. /.env
if [ "$CHECKOV_VERSION" != "false" ]; then
  if [ "$CHECKOV_VERSION" = "latest" ]; then
    pip3 install --no-cache-dir checkov
  else
    pip3 install --no-cache-dir "checkov==${CHECKOV_VERSION}"
  fi
fi
