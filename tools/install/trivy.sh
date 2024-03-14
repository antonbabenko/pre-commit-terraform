#!/usr/bin/env bash
set -eo pipefail
# shellcheck disable=SC1091 # Created in Dockerfile before execution of this script
source /.env

if [[ $TRIVY_VERSION != false ]]; then

  if [[ $TARGETARCH != amd64 ]]; then
    readonly ARCH="$TARGETARCH"
  else
    readonly ARCH="64bit"
  fi

  readonly RELEASES="https://api.github.com/repos/aquasecurity/trivy/releases"

  if [[ $TRIVY_VERSION == latest ]]; then
    curl -L "$(curl -s ${RELEASES}/latest | grep -o -E -i -m 1 "https://.+?/trivy_.+?_${TARGETOS}-${ARCH}.tar.gz")" > trivy.tar.gz
  else
    curl -L "$(curl -s ${RELEASES} | grep -o -E -i -m 1 "https://.+?/v${TRIVY_VERSION}/trivy_.+?_${TARGETOS}-${ARCH}.tar.gz")" > trivy.tar.gz
  fi

  tar -xzf trivy.tar.gz trivy
  rm trivy.tar.gz
fi
