#!/usr/bin/env bash
set -eo pipefail
# shellcheck disable=SC1091 # Created in Dockerfile before execution of this script
source /.env

if [[ $HCLEDIT_VERSION != false ]]; then
  readonly RELEASES="https://api.github.com/repos/minamijoyo/hcledit/releases"

  if [[ $HCLEDIT_VERSION == latest ]]; then
    curl -L "$(curl -s ${RELEASES}/latest | grep -o -E -m 1 "https://.+?_${TARGETOS}_${TARGETARCH}.tar.gz")" > hcledit.tgz
  else
    curl -L "$(curl -s ${RELEASES} | grep -o -E -m 1 "https://.+?${HCLEDIT_VERSION}_${TARGETOS}_${TARGETARCH}.tar.gz")" > hcledit.tgz
  fi

  tar -xzf hcledit.tgz hcledit
  rm hcledit.tgz
fi
