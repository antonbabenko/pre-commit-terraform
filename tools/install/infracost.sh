#!/usr/bin/env bash
set -eo pipefail
# shellcheck disable=SC1091 # Created in Dockerfile before execution of this script
source /.env

if [[ $INFRACOST_VERSION != false ]]; then
  readonly RELEASES="https://api.github.com/repos/infracost/infracost/releases"

  if [[ $INFRACOST_VERSION == latest ]]; then
    curl -L "$(curl -s ${RELEASES}/latest | grep -o -E -m 1 "https://.+?-${TARGETOS}-${TARGETARCH}.tar.gz")" > infracost.tgz
  else
    curl -L "$(curl -s ${RELEASES} | grep -o -E "https://.+?v${INFRACOST_VERSION}/infracost-${TARGETOS}-${TARGETARCH}.tar.gz")" > infracost.tgz
  fi

  tar -xzf infracost.tgz
  rm infracost.tgz
  mv "infracost-${TARGETOS}-${TARGETARCH}" infracost
fi
