#!/usr/bin/env bash
set -eo pipefail
# shellcheck disable=SC1091 # Created by Dockerfile above script call
source /.env

if [[ $TRIVY_VERSION != false ]]; then

  if [[ $TARGETARCH != amd64 ]]; then
    ARCH="$TARGETARCH"
  else
    ARCH="64bit"
  fi

  TRIVY_RELEASES="https://api.github.com/repos/aquasecurity/trivy/releases"

  if [[ $TRIVY_VERSION == latest ]]; then
    curl -L "$(curl -s ${TRIVY_RELEASES}/latest | grep -o -E -i -m 1 "https://.+?/trivy_.+?_${TARGETOS}-${ARCH}.tar.gz")" > trivy.tar.gz
  else
    curl -L "$(curl -s ${TRIVY_RELEASES} | grep -o -E -i -m 1 "https://.+?/v${TRIVY_VERSION}/trivy_.+?_${TARGETOS}-${ARCH}.tar.gz")" > trivy.tar.gz
  fi

  tar -xzf trivy.tar.gz trivy
  rm trivy.tar.gz
fi
