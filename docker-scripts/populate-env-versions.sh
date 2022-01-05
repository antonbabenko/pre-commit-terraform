#!/usr/bin/env ash
# shellcheck shell=dash

set -exuo pipefail

override_or_latest() {
  if [ "$1" = "false" ]; then
    echo -n "latest"
  else
    echo -n "$1"
  fi
}

if [ "$INSTALL_ALL" != "false" ]; then
  {
    echo "export CHECKOV_VERSION=$(override_or_latest "${CHECKOV_VERSION}")"
    echo "export INFRACOST_VERSION=$(override_or_latest "${INFRACOST_VERSION}")"
    echo "export TERRAFORM_DOCS_VERSION=$(override_or_latest "${TERRAFORM_DOCS_VERSION}")"
    echo "export TERRAGRUNT_VERSION=$(override_or_latest "${TERRAGRUNT_VERSION}")"
    echo "export TERRASCAN_VERSION=$(override_or_latest "${TERRASCAN_VERSION}")"
    echo "export TFLINT_VERSION=$(override_or_latest "${TFLINT_VERSION}")"
    echo "export TFSEC_VERSION=$(override_or_latest "${TFSEC_VERSION}")"
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
