#!/usr/bin/env bash
set -eo pipefail
# shellcheck disable=SC1091 # Created by Dockerfile above script call
source /.env

if [[ $TFLINT_VERSION != false ]]; then
  TFLINT_RELEASES="https://api.github.com/repos/terraform-linters/tflint/releases"

  if [[ $TFLINT_VERSION == latest ]]; then
    curl -L "$(curl -s ${TFLINT_RELEASES}/latest | grep -o -E -m 1 "https://.+?_${TARGETOS}_${TARGETARCH}.zip")" > tflint.zip
  else
    curl -L "$(curl -s ${TFLINT_RELEASES} | grep -o -E "https://.+?/v${TFLINT_VERSION}/tflint_${TARGETOS}_${TARGETARCH}.zip")" > tflint.zip
  fi

  unzip tflint.zip
  rm tflint.zip
fi
