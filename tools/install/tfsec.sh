#!/usr/bin/env bash
set -eo pipefail
# shellcheck disable=SC1091 # Created in Dockerfile before execution of this script
source /.env

if [[ $TFSEC_VERSION != false ]]; then
  readonly RELEASES="https://api.github.com/repos/aquasecurity/tfsec/releases"

  if [[ $TFSEC_VERSION == latest ]]; then
    curl -L "$(curl -s ${RELEASES}/latest | grep -o -E -m 1 "https://.+?/tfsec-${TARGETOS}-${TARGETARCH}")" > tfsec
  else
    curl -L "$(curl -s ${RELEASES} | grep -o -E -m 1 "https://.+?v${TFSEC_VERSION}/tfsec-${TARGETOS}-${TARGETARCH}")" > tfsec
  fi

  chmod +x tfsec
fi
