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
  {
    echo "export CHECKOV_VERSION=${CHECKOV_VERSION}"
    echo "export INFRACOST_VERSION=${INFRACOST_VERSION}"
    echo "export TERRAFORM_DOCS_VERSION=${TERRAFORM_DOCS_VERSION}"
    echo "export TERRAGRUNT_VERSION=${TERRAGRUNT_VERSION}"
    echo "export TERRASCAN_VERSION=${TERRASCAN_VERSION}"
    echo "export TFLINT_VERSION=${TFLINT_VERSION}"
    echo "export TFSEC_VERSION=${TFSEC_VERSION}"
  } >> /.env
fi
