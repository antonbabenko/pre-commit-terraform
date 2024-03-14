#!/usr/bin/env bash
# shellcheck disable=SC2155 # No way to assign to readonly variable in separate lines
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=_common.sh
. "$SCRIPT_DIR/_common.sh"

#
# Unique part
#

if [[ $TARGETARCH != amd64 ]]; then
  readonly ARCH="$TARGETARCH"
else
  readonly ARCH="64bit"
fi

readonly RELEASES="https://api.github.com/repos/aquasecurity/${TOOL}/releases"

if [[ $VERSION == latest ]]; then
  curl -L "$(curl -s "${RELEASES}/latest" | grep -o -E -i -m 1 "https://.+?/${TOOL}_.+?_${TARGETOS}-${ARCH}.tar.gz")" > "${TOOL}.tgz"
else
  curl -L "$(curl -s "${RELEASES}" | grep -o -E -i -m 1 "https://.+?/v${VERSION}/${TOOL}_.+?_${TARGETOS}-${ARCH}.tar.gz")" > "${TOOL}.tgz"
fi

tar -xzf "${TOOL}.tgz" "$TOOL"
rm "${TOOL}.tgz"
