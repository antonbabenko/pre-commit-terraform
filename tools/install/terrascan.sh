#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
# shellcheck source=_common.sh
. "$SCRIPT_DIR/_common.sh"

#
# Unique part
#

[[ $TARGETARCH == amd64 ]] && ARCH="x86_64" || ARCH="$TARGETARCH"
readonly ARCH
# Convert the first letter to Uppercase
OS="${TARGETOS^}"

GH_ORG="tenable"
GH_RELEASE_REGEX_SPECIFIC_VERSION="https://.+?${VERSION}_${OS}_${ARCH}.tar.gz"
GH_RELEASE_REGEX_LATEST="https://.+?_${OS}_${ARCH}.tar.gz"
DISTRIBUTED_AS="tar.gz"

common::install_from_gh_release "$GH_ORG" "$DISTRIBUTED_AS" \
  "$GH_RELEASE_REGEX_LATEST" "$GH_RELEASE_REGEX_SPECIFIC_VERSION"

# Download (caching) terrascan rego policies to save time during terrascan run
# https://runterrascan.io/docs/usage/_print/#pg-2cba380a2ef14e4ae3c674e02c5f9f53
./"$TOOL" init
