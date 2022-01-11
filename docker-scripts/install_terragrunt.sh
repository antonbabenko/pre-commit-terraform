#!/usr/bin/env ash
# shellcheck shell=dash

set -euo pipefail

. /.env
if [ "$TERRAGRUNT_VERSION" != "false" ]; then
  export PCT_VERSION=$TERRAGRUNT_VERSION
  export PCT_GITHUB_USER=gruntwork-io
  export PCT_GITHUB_PROJECT=terragrunt
  export PCT_BIN_NAME=terragrunt
  export PCT_PREFIX="${PCT_BIN_NAME}"
  export PCT_ASSET_INCLUDE_VERSION=false
  export PCT_INFIX="_linux_"
  export PCT_ARCH=${ARCH}
  /docker-scripts/install-from-github.sh
fi
