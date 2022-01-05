#!/usr/bin/env ash
# shellcheck shell=dash

set -exuo pipefail

. /.env
if [ "$TERRAFORM_DOCS_VERSION" != "false" ]; then
  export PCT_VERSION=$TERRAFORM_DOCS_VERSION
  export PCT_GITHUB_USER=terraform-docs
  export PCT_GITHUB_PROJECT=terraform-docs
  export PCT_BIN_NAME=terraform-docs
  export PCT_PREFIX="${PCT_BIN_NAME}-v"
  export PCT_INFIX="-linux-"
  export PCT_ARCH=${ARCH}
  export PCT_SUFFIX=.tar.gz
  /docker-scripts/install-from-github.sh
fi
