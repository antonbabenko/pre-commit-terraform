#!/usr/bin/env ash
# shellcheck shell=dash

set -euo pipefail

if [ "${PRE_COMMIT_VERSION}" = "latest" ]; then
  pip3 install --no-cache-dir pre-commit
else
  pip3 install --no-cache-dir "pre-commit==${PRE_COMMIT_VERSION}"
fi

# reinstall latest pip
python3 -m pip install --no-cache-dir --upgrade pip
