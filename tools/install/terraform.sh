#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
# shellcheck source=_common.sh
. "$SCRIPT_DIR/_common.sh"

#
# Unique part
#
# shellcheck disable=SC2153 # We are using the variable from _common.sh
if [[ $VERSION == latest ]]; then
  version="$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | grep -o -E -m 1 "[0-9.]+")"
else
  version=$VERSION
fi
readonly version

curl -L "https://releases.hashicorp.com/terraform/${version}/${TOOL}_${version}_${TARGETOS}_${TARGETARCH}.zip" > "${TOOL}.zip"
unzip "${TOOL}.zip" "$TOOL"
rm "${TOOL}.zip"
