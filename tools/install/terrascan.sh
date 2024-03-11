#!/usr/bin/env bash
set -eo pipefail
# shellcheck disable=SC1091 # Created by Dockerfile above script call
source /.env

if [[ $TERRASCAN_VERSION != false ]]; then
  if [[ $TARGETARCH != amd64 ]]; then
    ARCH="$TARGETARCH"
  else
    ARCH="x86_64"
  fi
  # Convert the first letter to Uppercase
  OS="$(
    echo "${TARGETOS}" | cut -c1 | tr '[:lower:]' '[:upper:]' | xargs echo -n
    echo "${TARGETOS}" | cut -c2-
  )"

  TERRASCAN_RELEASES="https://api.github.com/repos/tenable/terrascan/releases"

  if [[ $TERRASCAN_VERSION == latest ]]; then
    curl -L "$(curl -s ${TERRASCAN_RELEASES}/latest | grep -o -E -m 1 "https://.+?_${OS}_${ARCH}.tar.gz")" > terrascan.tar.gz
  else
    curl -L "$(curl -s ${TERRASCAN_RELEASES} | grep -o -E "https://.+?${TERRASCAN_VERSION}_${OS}_${ARCH}.tar.gz")" > terrascan.tar.gz
  fi

  tar -xzf terrascan.tar.gz terrascan
  rm terrascan.tar.gz
  ./terrascan init
fi
