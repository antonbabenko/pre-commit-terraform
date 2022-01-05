#!/usr/bin/env ash
# shellcheck shell=dash

set -exuo pipefail

. /.env
F=tools_versions_info
pre-commit --version >> $F
terraform --version | head -n 1 >> $F
(if [ "$CHECKOV_VERSION" != "false" ]; then echo "checkov $(checkov --version)" >> $F; else echo "checkov SKIPPED" >> $F; fi)
(if [ "$INFRACOST_VERSION" != "false" ]; then infracost --version >> $F; else echo "infracost SKIPPED" >> $F; fi)
(if [ "$TERRAFORM_DOCS_VERSION" != "false" ]; then terraform-docs --version >> $F; else echo "terraform-docs SKIPPED" >> $F; fi)
(if [ "$TERRAGRUNT_VERSION" != "false" ]; then terragrunt --version >> $F; else echo "terragrunt SKIPPED" >> $F; fi)
(if [ "$TERRASCAN_VERSION" != "false" ]; then echo "terrascan $(terrascan version)" >> $F; else echo "terrascan SKIPPED" >> $F; fi)
(if [ "$TFLINT_VERSION" != "false" ]; then tflint --version >> $F; else echo "tflint SKIPPED" >> $F; fi)
(if [ "$TFSEC_VERSION" != "false" ]; then echo "tfsec $(tfsec --version)" >> $F; else echo "tfsec SKIPPED" >> $F; fi)
echo -n "\n\n" && cat $F && echo -n "\n\n"
