#!/usr/bin/env bash
set -eo pipefail
# shellcheck disable=SC1091 # Created by Dockerfile above script call
source /.env

# TFUpdate
if [[ $TFUPDATE_VERSION != false ]]; then
  TFUPDATE_RELEASES="https://api.github.com/repos/minamijoyo/tfupdate/releases"

  if [[ $TFUPDATE_VERSION == latest ]]; then
    curl -L "$(curl -s ${TFUPDATE_RELEASES}/latest | grep -o -E -m 1 "https://.+?_${TARGETOS}_${TARGETARCH}.tar.gz")" > tfupdate.tgz
  else
    curl -L "$(curl -s ${TFUPDATE_RELEASES} | grep -o -E -m 1 "https://.+?${TFUPDATE_VERSION}_${TARGETOS}_${TARGETARCH}.tar.gz")" > tfupdate.tgz
  fi

  tar -xzf tfupdate.tgz tfupdate
  rm tfupdate.tgz
fi
