#!/usr/bin/env bash

set -euo pipefail
readonly current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd -P)"
readonly SCRIPT_DIR="$(cd "$current_dir/../../"; pwd -P)"

source "${current_dir}"/../bach.sh
source "${current_dir}"/../../hooks/_common.sh

function test-common::initialize {
    common::initialize "$SCRIPT_DIR"
}
function test-common::initialize-assert {
    . "$SCRIPT_DIR/../lib_getopt"
}


function test-common::parse_cmdline {
  common::parse_cmdline '--args=--config=__GIT_WORKING_DIR__/${CONFIG_NAME}.${CONFIG_EXT}' '--args=--module' 'environment/qa/backends.tf environment/qa/main.tf test.tfvars environment/qa/data.tf test2.tfvars environment/qa/outputs.tf modules/aws-environment/lambdas.tf'
  @assert-equals "--config-file=test/infracost.yml" "${ARGS[@]}"
}


