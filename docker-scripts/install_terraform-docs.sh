#!/usr/bin/env ash
# shellcheck shell=dash

set -exuo pipefail

. /.env
if [ "$TERRAFORM_DOCS_VERSION" != "false" ]; then

  TERRAFORM_DOCS_RELEASES="https://api.github.com/repos/terraform-docs/terraform-docs/releases"
  if [ "$TERRAFORM_DOCS_VERSION" = "latest" ]; then
    curl -L "$(curl -sS ${TERRAFORM_DOCS_RELEASES}/latest | grep -o -E -m 1 "https://.+?-linux-${ARCH}.tar.gz")" > terraform-docs.tgz
  else
    curl -sS -L "$(curl -sS ${TERRAFORM_DOCS_RELEASES} | grep -o -E "https://.+?v${TERRAFORM_DOCS_VERSION}-linux-${ARCH}.tar.gz")" > terraform-docs.tgz
  fi
  tar -xzf terraform-docs.tgz terraform-docs
  chmod +x terraform-docs
  mv terraform-docs "${VIRTUAL_ENV}/bin/"
  rm terraform-docs.tgz
fi
