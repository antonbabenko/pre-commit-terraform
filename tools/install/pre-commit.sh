#!/usr/bin/env bash
set -eo pipefail

if [[ $PRE_COMMIT_VERSION == latest ]]; then
  pip3 install --no-cache-dir pre-commit
else
  pip3 install --no-cache-dir "pre-commit==${PRE_COMMIT_VERSION}"
fi
