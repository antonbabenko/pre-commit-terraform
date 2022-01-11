#!/usr/bin/env ash
# shellcheck shell=dash

set -euo pipefail

. /.env
F="${VIRTUAL_ENV}/tools_versions_info"
{
  pre-commit --version
  terraform --version | head -n 1
  (if [ "$CHECKOV_VERSION" != "false" ]; then echo "checkov $(checkov --version)"; else echo "checkov SKIPPED"; fi)
  (if [ "$INFRACOST_VERSION" != "false" ]; then infracost --version; else echo "infracost SKIPPED"; fi)
  (if [ "$TERRAFORM_DOCS_VERSION" != "false" ]; then terraform-docs --version; else echo "terraform-docs SKIPPED"; fi)
  (if [ "$TERRAGRUNT_VERSION" != "false" ]; then terragrunt --version; else echo "terragrunt SKIPPED"; fi)
  (if [ "$TERRASCAN_VERSION" != "false" ]; then echo "terrascan $(terrascan version)"; else echo "terrascan SKIPPED"; fi)
  (if [ "$TFLINT_VERSION" != "false" ]; then tflint --version; else echo "tflint SKIPPED"; fi)
  (if [ "$TFSEC_VERSION" != "false" ]; then echo "tfsec $(tfsec --version)"; else echo "tfsec SKIPPED"; fi)
} >> "$F"
printf '\n\n' && cat "$F" && printf '\n\n'
