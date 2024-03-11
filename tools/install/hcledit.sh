#!/usr/bin/env bash
set -eo pipefail
# shellcheck disable=SC1091 # Created by Dockerfile above script call
source /.env

# hcledit
if [[ $HCLEDIT_VERSION != false ]]; then
  HCLEDIT_RELEASES="https://api.github.com/repos/minamijoyo/hcledit/releases"

  if [[ $HCLEDIT_VERSION == latest ]]; then
    curl -L "$(curl -s ${HCLEDIT_RELEASES}/latest | grep -o -E -m 1 "https://.+?_${TARGETOS}_${TARGETARCH}.tar.gz")" > hcledit.tgz
  else
    curl -L "$(curl -s ${HCLEDIT_RELEASES} | grep -o -E -m 1 "https://.+?${HCLEDIT_VERSION}_${TARGETOS}_${TARGETARCH}.tar.gz")" > hcledit.tgz
  fi

  tar -xzf hcledit.tgz hcledit
  rm hcledit.tgz
fi
