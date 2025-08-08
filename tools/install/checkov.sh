#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
# shellcheck source=_common.sh
. "$SCRIPT_DIR/_common.sh"

#
# Unique part
#

apk add --no-cache \
  gcc=~14 \
  libffi-dev=~3 \
  musl-dev=~1

if [[ $VERSION == latest ]]; then
  pip3 install --no-cache-dir "${TOOL}"
else
  pip3 install --no-cache-dir "${TOOL}==${VERSION}"
fi
pip3 check
