#!/usr/bin/env ash
# shellcheck shell=dash

set -exuo pipefail

. /.env
if [ "$TFLINT_VERSION" != "false" ]; then
  export PCT_VERSION=$TFLINT_VERSION
  export PCT_GITHUB_USER=terraform-linters
  export PCT_GITHUB_PROJECT=tflint
  export PCT_BIN_NAME=tflint
  export PCT_PREFIX="${PCT_BIN_NAME}"
  export PCT_ASSET_INCLUDE_VERSION=false
  export PCT_INFIX="_linux_"
  export PCT_ARCH=${ARCH}
  export PCT_SUFFIX=.zip
  /docker-scripts/install-from-github.sh
fi
