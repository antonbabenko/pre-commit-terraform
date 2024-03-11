#!/usr/bin/env bash
set -eo pipefail
# shellcheck disable=SC1091 # Created by Dockerfile above script call
source /.env

if [[ $TERRAFORM_DOCS_VERSION != false ]]; then
  TERRAFORM_DOCS_RELEASES="https://api.github.com/repos/terraform-docs/terraform-docs/releases"

  if [[ $TERRAFORM_DOCS_VERSION == latest ]]; then
    curl -L "$(curl -s ${TERRAFORM_DOCS_RELEASES}/latest | grep -o -E -m 1 "https://.+?-${TARGETOS}-${TARGETARCH}.tar.gz")" > terraform-docs.tgz
  else
    curl -L "$(curl -s ${TERRAFORM_DOCS_RELEASES} | grep -o -E "https://.+?v${TERRAFORM_DOCS_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz")" > terraform-docs.tgz
  fi

  tar -xzf terraform-docs.tgz terraform-docs
  rm terraform-docs.tgz
  chmod +x terraform-docs
fi
