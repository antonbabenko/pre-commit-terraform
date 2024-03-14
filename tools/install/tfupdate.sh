#!/usr/bin/env bash
set -eo pipefail
# shellcheck disable=SC1091 # Created in Dockerfile before execution of this script
source /.env

# TFUpdate
if [[ $TFUPDATE_VERSION != false ]]; then
  readonly RELEASES="https://api.github.com/repos/minamijoyo/tfupdate/releases"

  if [[ $TFUPDATE_VERSION == latest ]]; then
    curl -L "$(curl -s ${RELEASES}/latest | grep -o -E -m 1 "https://.+?_${TARGETOS}_${TARGETARCH}.tar.gz")" > tfupdate.tgz
  else
    curl -L "$(curl -s ${RELEASES} | grep -o -E -m 1 "https://.+?${TFUPDATE_VERSION}_${TARGETOS}_${TARGETARCH}.tar.gz")" > tfupdate.tgz
  fi

  tar -xzf tfupdate.tgz tfupdate
  rm tfupdate.tgz
fi
