#!/usr/bin/env bash
set -eo pipefail
# shellcheck disable=SC1091 # Created by Dockerfile above script call
source /.env

if [[ $INFRACOST_VERSION != false ]]; then
  INFRACOST_RELEASES="https://api.github.com/repos/infracost/infracost/releases"

  if [[ $INFRACOST_VERSION == latest ]]; then
    curl -L "$(curl -s ${INFRACOST_RELEASES}/latest | grep -o -E -m 1 "https://.+?-${TARGETOS}-${TARGETARCH}.tar.gz")" > infracost.tgz
  else
    curl -L "$(curl -s ${INFRACOST_RELEASES} | grep -o -E "https://.+?v${INFRACOST_VERSION}/infracost-${TARGETOS}-${TARGETARCH}.tar.gz")" > infracost.tgz
  fi

  tar -xzf infracost.tgz
  rm infracost.tgz
  mv "infracost-${TARGETOS}-${TARGETARCH}" infracost
fi
