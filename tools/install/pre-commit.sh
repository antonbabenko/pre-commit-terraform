#!/usr/bin/env bash
# shellcheck disable=SC2155 # No way to assign to readonly variable in separate lines
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# shellcheck source=_common.sh
. "$SCRIPT_DIR/_common.sh"

#
# Unique part
#

if [[ $VERSION == latest ]]; then
  pip3 install --no-cache-dir "$TOOL"
else
  pip3 install --no-cache-dir "${TOOL}==${VERSION}"
fi
