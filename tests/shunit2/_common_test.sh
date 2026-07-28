#!/usr/bin/env bash

# shellcheck disable=SC2034 # shunit2 constant
readonly SHUNIT_TEST_PREFIX="_common.sh__"

function oneTimeSetUp {
  # Load stuff for tests.
  . ../../hooks/_common.sh
  # Global ENV vars in --args
  export CONFIG_FILE=.tflint.hcl
  export CONFIG_NAME=.tflint
  export CONFIG_EXT=hcl
  # Disable hooks clolrs
  export PRE_COMMIT_COLOR="never"
}

function test__HOOK_ID {
  assertEquals "_common_test" "$HOOK_ID"
}

# function test__initialize {
#   Nothing to test?
# }

function test__parse_cmdline {
  # Pass test parameters to the function being tested
  # shellcheck disable=SC2016 # IT should not expand
  common::parse_cmdline \
    '--args=--config-file=.tfsec.json' \
    "--hook-config='.totalHourlyCost >= 0.1'" \
    '--init-args=-get=true' \
    '--tf-init-args=-get=true' \
    '--envs=AWS_DEFAULT_REGION="us-west-2"' \
    '--env-vars=AWS_ACCESS_KEY_ID="anaccesskey"' \
    \
    '-a --force-all-dirs' \
    '-h ".totalHourlyCost|tonumber > 1"' \
    '-i -upgrade' \
    '-e AWS_SECRET_ACCESS_KEY="asecretkey"' \
    \
    '--args=--exclude-downloaded-modules' \
    '-h ".projects[].diff.totalMonthlyCost|tonumber!=10000"' \
    '-h [.projects[].diff.totalMonthlyCost | select (.!=null) | tonumber] | add > 1000' \
    '--hook-config=--retry-once-with-cleanup=true' \
    '-a --concise-output' \
    '--args=--config-file=__GIT_WORKING_DIR__/.tfsec.json' \
    '--hook-config=--retry-once-with-cleanup=true' \
    '--args=--config=__GIT_WORKING_DIR__/${CONFIG_FILE}' \
    '-a --config=__GIT_WORKING_DIR__/${CONFIG_NAME}.${CONFIG_EXT}' \
    'environment/qa/backends.tf' \
    'environment/qa/main.tf' \
    'modules/aws-environment/lambdas.tf' \
    'environment/qa/data.tf' \
    'environment/qa/outputs.tf' \
    'environment/qa/versions.tf'

  #
  # Test Global ENVs changes
  #

  # shellcheck disable=SC2016 # IT should not expand
  local expected='--config-file=.tfsec.json --force-all-dirs --exclude-downloaded-modules --concise-output --config-file=__GIT_WORKING_DIR__/.tfsec.json --config=__GIT_WORKING_DIR__/${CONFIG_FILE} --config=__GIT_WORKING_DIR__/${CONFIG_NAME}.${CONFIG_EXT}'
  assertEquals "ARGS -" "$expected" "${ARGS[*]}"
  # Extra space for `-h`. No matter, because in function it spitted to array by spaces
  local expected="'.totalHourlyCost >= 0.1';  \".totalHourlyCost|tonumber > 1\";  \".projects[].diff.totalMonthlyCost|tonumber!=10000\";  [.projects[].diff.totalMonthlyCost | select (.!=null) | tonumber] | add > 1000; --retry-once-with-cleanup=true; --retry-once-with-cleanup=true;"
  assertEquals "HOOK_CONFIG -" "$expected" "${HOOK_CONFIG[*]}"
  # Extra space for `-i`.No matter, because in function it spitted to array by spaces
  local expected='-get=true -get=true  -upgrade'
  assertEquals "TF_INIT_ARGS -" "$expected" "${TF_INIT_ARGS[*]}"
  # Extra space for `-e`. No matter, because in function it spitted to array by spaces
  local expected='AWS_DEFAULT_REGION="us-west-2" AWS_ACCESS_KEY_ID="anaccesskey"  AWS_SECRET_ACCESS_KEY="asecretkey"'
  assertEquals "ENV_VARS -" "$expected" "${ENV_VARS[*]}"

  local expected='environment/qa/backends.tf environment/qa/main.tf modules/aws-environment/lambdas.tf environment/qa/data.tf environment/qa/outputs.tf environment/qa/versions.tf'
  assertEquals "FILES -" "$expected" "${FILES[*]}"
}

function test__parse_and_export_env_vars {
  # Init "GLOBAL ENV"
  # shellcheck disable=SC2016 # IT should not expand
  local ARGS=(
    '--args=--config=__GIT_WORKING_DIR__/${CONFIG_FILE}'
    '--args=--config=__GIT_WORKING_DIR__/${CONFIG_NAME}.${CONFIG_EXT}'
    '--args=--module'
  )
  # Pass test parameters to the function being tested (only GLOBAL ENV - ARGS)
  common::parse_and_export_env_vars

  local expected=(
    '--args=--config=__GIT_WORKING_DIR__/.tflint.hcl'
    '--args=--config=__GIT_WORKING_DIR__/.tflint.hcl'
    '--args=--module'
  )
  assertEquals "${expected[*]}" "${ARGS[*]}"
}

# Load shUnit2. File populated to PATH from https://github.com/kward/shunit2
. shunit2
