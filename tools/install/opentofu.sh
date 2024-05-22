#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
# shellcheck source=_common.sh
. "$SCRIPT_DIR/_common.sh"

#
# Unique part
#
GH_ORG="opentofu"
GH_RELEASE_REGEX_SPECIFIC_VERSION="https://.+?v${VERSION}_${TARGETOS}_${TARGETARCH}.tar.gz"
GH_RELEASE_REGEX_LATEST="https://.+?_${TARGETOS}_${TARGETARCH}.tar.gz"
DISTRIBUTED_AS="tar.gz"
UNUSUAL_TOOL_NAME_IN_PKG="tofu"

common::install_from_gh_release "$GH_ORG" "$DISTRIBUTED_AS" \
  "$GH_RELEASE_REGEX_LATEST" "$GH_RELEASE_REGEX_SPECIFIC_VERSION" \
  "$UNUSUAL_TOOL_NAME_IN_PKG"

# restore original binary name
mv "$TOOL" "$UNUSUAL_TOOL_NAME_IN_PKG"
