#!/usr/bin/env ash
# shellcheck shell=dash

set -exuo pipefail

# shellcheck source=/dev/null
. /.env
if [ "${TERRAFORM_VERSION}" = "latest" ]; then
  TERRAFORM_VERSION="$(curl -sS https://api.github.com/repos/hashicorp/terraform/releases/latest | jq -r '.tag_name' | grep -o -E -m 1 "[0-9.]+")"
fi

curl -sS -L "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip" -o terraform.zip
unzip -q terraform.zip terraform
chmod a+x terraform
mv terraform "${VIRTUAL_ENV}/bin/"
rm terraform.zip
