#!/usr/bin/env ash
# shellcheck shell=dash

set -exuo pipefail

. /.env
if [ "$INFRACOST_VERSION" != "false" ]; then
  export PCT_VERSION=$INFRACOST_VERSION
  export PCT_GITHUB_USER=infracost
  export PCT_GITHUB_PROJECT=infracost
  export PCT_BIN_NAME=infracost
  export PCT_PREFIX="${PCT_BIN_NAME}-"
  export PCT_ASSET_INCLUDE_VERSION=false
  export PCT_INFIX="linux-"
  export PCT_ARCH=${ARCH}
  export PCT_SUFFIX=".tar.gz"
  export PCT_ASSET_BIN_NAME="infracost-linux-amd64"
  /docker-scripts/install-from-github.sh
fi
