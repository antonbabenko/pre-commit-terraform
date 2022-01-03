#!/usr/bin/env ash
# shellcheck shell=dash

set -exuo pipefail

if [ "$INSTALL_ALL" != "false" ]; then
  {
    echo "export CHECKOV_VERSION=latest"
    echo "export INFRACOST_VERSION=latest"
    echo "export TERRAFORM_DOCS_VERSION=latest"
    echo "export TERRAGRUNT_VERSION=latest"
    echo "export TERRASCAN_VERSION=latest"
    echo "export TFLINT_VERSION=latest"
    echo "export TFSEC_VERSION=latest"
  } >> /.env
else
  touch /.env
fi
