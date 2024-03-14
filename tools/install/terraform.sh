#!/usr/bin/env bash
# shellcheck disable=SC2155 # No way to assign to readonly variable in separate lines
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=_common.sh
. "$SCRIPT_DIR/_common.sh"

#
# Unique part
#

if [[ $VERSION == latest ]]; then
  VERSION="$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | grep -o -E -m 1 "[0-9.]+")"
fi

curl -L "https://releases.hashicorp.com/terraform/${VERSION}/${TOOL}_${VERSION}_${TARGETOS}_${TARGETARCH}.zip" > "${TOOL}.zip"
unzip "${TOOL}.zip" "$TOOL"
rm "${TOOL}.zip"
