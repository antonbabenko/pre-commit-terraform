#!/usr/bin/env bash
# shellcheck disable=SC2155 # No way to assign to readonly variable in separate lines
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=_common.sh
. "$SCRIPT_DIR/_common.sh"

#
# Unique part
#

readonly RELEASES="https://api.github.com/repos/terraform-linters/${TOOL}/releases"

if [[ $VERSION == latest ]]; then
  curl -L "$(curl -s "${RELEASES}/latest" | grep -o -E -m 1 "https://.+?_${TARGETOS}_${TARGETARCH}.zip")" > "${TOOL}.zip"
else
  curl -L "$(curl -s "${RELEASES}" | grep -o -E "https://.+?/v${VERSION}/${TOOL}_${TARGETOS}_${TARGETARCH}.zip")" > "${TOOL}.zip"
fi

unzip "${TOOL}.zip"
rm "${TOOL}.zip"
