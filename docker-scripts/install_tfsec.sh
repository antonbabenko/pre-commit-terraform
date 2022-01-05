#!/usr/bin/env ash
# shellcheck shell=dash

set -exuo pipefail

. /.env
if [ "$TFSEC_VERSION" != "false" ]; then
  export PCT_VERSION=$TFSEC_VERSION
  export PCT_GITHUB_USER=aquasecurity
  export PCT_GITHUB_PROJECT=tfsec
  export PCT_BIN_NAME=tfsec
  export PCT_PREFIX="${PCT_BIN_NAME}"
  export PCT_ASSET_INCLUDE_VERSION=false
  export PCT_INFIX="-linux-"
  export PCT_ARCH=${ARCH}
  /docker-scripts/install-from-github.sh
fi
