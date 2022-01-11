#!/usr/bin/env ash
# shellcheck shell=dash

set -euo pipefail

. /.env
if [ "${TERRAFORM_VERSION}" = "latest" ]; then
  TERRAFORM_VERSION="$(curl -sSfL https://api.github.com/repos/hashicorp/terraform/releases/latest | jq -r '.tag_name' | grep -o -E -m 1 "[0-9.]+")"
fi

echo Downloading...
curl -sSfL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip" -o terraform.zip
echo Downloaded

unzip -q terraform.zip terraform
chmod a+x terraform
mv terraform "${VIRTUAL_ENV}/bin/"
rm terraform.zip
