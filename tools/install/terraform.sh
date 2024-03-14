#!/usr/bin/env bash
# shellcheck disable=SC2155 # No way to assign to readonly variable in separate lines
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=_common.sh
. "$SCRIPT_DIR/_common.sh"

#
# Unique part
#
# shellcheck disable=SC2153 # We are using the variable from _common.sh
if [[ $VERSION == latest ]]; then
  readonly version="$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | grep -o -E -m 1 "[0-9.]+")"
fi

curl -L "https://releases.hashicorp.com/terraform/${version}/${TOOL}_${version}_${TARGETOS}_${TARGETARCH}.zip" > "${TOOL}.zip"
unzip "${TOOL}.zip" "$TOOL"
rm "${TOOL}.zip"
