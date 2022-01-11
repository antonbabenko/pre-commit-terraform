#!/usr/bin/env ash
# shellcheck shell=dash

set -euo pipefail

. /.env
if [ "$CHECKOV_VERSION" != "false" ]; then
  if [ "$CHECKOV_VERSION" = "latest" ]; then
    pip3 install --no-cache-dir checkov
  else
    pip3 install --no-cache-dir "checkov==${CHECKOV_VERSION}"
  fi
  # reinstall latest pip
  python3 -m pip install --no-cache-dir --upgrade pip
fi
