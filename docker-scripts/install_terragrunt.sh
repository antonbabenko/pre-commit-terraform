#!/usr/bin/env ash
# shellcheck shell=dash

set -exuo pipefail

. /.env
if [ "$TERRAGRUNT_VERSION" != "false" ]; then

  TERRAGRUNT_RELEASES="https://api.github.com/repos/gruntwork-io/terragrunt/releases"
  if [ "$TERRAGRUNT_VERSION" = "latest" ]; then
    curl -sS -L "$(curl -sS ${TERRAGRUNT_RELEASES}/latest | grep -o -E -m 1 "https://.+?/terragrunt_linux_${ARCH}")" > "${VIRTUAL_ENV}/bin/terragrunt"
  else
    curl -sS -L "$(curl -sS ${TERRAGRUNT_RELEASES} | grep -o -E "https://.+?v${TERRAGRUNT_VERSION}/terragrunt_linux_${ARCH}")" > "${VIRTUAL_ENV}/bin/terragrunt"
  fi
  chmod +x "${VIRTUAL_ENV}/bin/terragrunt"
fi
