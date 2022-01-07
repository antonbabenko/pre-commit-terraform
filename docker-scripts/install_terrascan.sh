#!/usr/bin/env ash
# shellcheck shell=dash

set -exuo pipefail

mkdir -p /root/.terrascan/pkg/policies/opa/rego/

. /.env
if [ "$TERRASCAN_VERSION" != "false" ]; then
  export PCT_VERSION=$TERRASCAN_VERSION
  export PCT_GITHUB_USER=accurics
  export PCT_GITHUB_PROJECT=terrascan
  export PCT_BIN_NAME=terrascan
  export PCT_PREFIX="${PCT_BIN_NAME}_"
  export PCT_INFIX="_Linux_"
  export PCT_ARCH=${ARCHX}
  export PCT_SUFFIX=.tar.gz
  export PCT_VERSION_PARAM="version"
  /docker-scripts/install-from-github.sh
  terrascan init
fi
