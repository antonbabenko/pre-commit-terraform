#!/usr/bin/env bash
set -eo pipefail
# shellcheck disable=SC1091 # Created in Dockerfile before execution of this script
source /.env

if [[ $TFLINT_VERSION != false ]]; then
  readonly RELEASES="https://api.github.com/repos/terraform-linters/tflint/releases"

  if [[ $TFLINT_VERSION == latest ]]; then
    curl -L "$(curl -s ${RELEASES}/latest | grep -o -E -m 1 "https://.+?_${TARGETOS}_${TARGETARCH}.zip")" > tflint.zip
  else
    curl -L "$(curl -s ${RELEASES} | grep -o -E "https://.+?/v${TFLINT_VERSION}/tflint_${TARGETOS}_${TARGETARCH}.zip")" > tflint.zip
  fi

  unzip tflint.zip
  rm tflint.zip
fi
