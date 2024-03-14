#!/usr/bin/env bash
set -eo pipefail
# shellcheck disable=SC1091 # Created in Dockerfile before execution of this script
source /.env

if [[ $TERRAGRUNT_VERSION != false ]]; then
  readonly RELEASES="https://api.github.com/repos/gruntwork-io/terragrunt/releases"

  if [[ $TERRAGRUNT_VERSION == latest ]]; then
    curl -L "$(curl -s ${RELEASES}/latest | grep -o -E -m 1 "https://.+?/terragrunt_${TARGETOS}_${TARGETARCH}")" > terragrunt
  else
    curl -L "$(curl -s ${RELEASES} | grep -o -E -m 1 "https://.+?v${TERRAGRUNT_VERSION}/terragrunt_${TARGETOS}_${TARGETARCH}")" > terragrunt
  fi

  chmod +x terragrunt
fi
