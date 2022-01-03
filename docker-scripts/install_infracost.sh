#!/usr/bin/env ash
# shellcheck shell=dash

set -exuo pipefail

# shellcheck source=/dev/null
. /.env
if [ "$INFRACOST_VERSION" != "false" ]; then
  INFRACOST_RELEASES="https://api.github.com/repos/infracost/infracost/releases"

  if [ "$INFRACOST_VERSION" = "latest" ]; then
    curl -sS -L "$(curl -s ${INFRACOST_RELEASES}/latest | grep -o -E -m 1 "https://.+?-linux-${ARCH}.tar.gz")" > infracost.tgz
  else
    curl -sS -L "$(curl -sS ${INFRACOST_RELEASES} | grep -o -E "https://.+?v${INFRACOST_VERSION}/infracost-linux-${ARCH}.tar.gz")" > infracost.tgz
  fi
  tar -xzf infracost.tgz
  rm infracost.tgz
  mv infracost-linux-amd64 "${VIRTUAL_ENV}/bin/infracost"
fi
