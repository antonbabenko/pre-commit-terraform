#!/usr/bin/env bash
set -eo pipefail

# Install terraform because pre-commit needs it
if [[ $TERRAFORM_VERSION == latest ]]; then
  TERRAFORM_VERSION="$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | grep -o -E -m 1 "[0-9.]+")"
fi

curl -L "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${TARGETOS}_${TARGETARCH}.zip" > terraform.zip
unzip terraform.zip terraform
rm terraform.zip
