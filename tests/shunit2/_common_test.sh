#!/usr/bin/env bash

function oneTimeSetUp {
  # Load include to test.
  . ../../hooks/_common.sh
}

function test__HOOK_ID {
  assertEquals "_common_test" "$HOOK_ID"
}

# function test__initialize {
#   Nothing to test?
# }

function test__parse_cmdline {

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
    'environment/qa/backends.tf' \
    'environment/qa/main.tf' \
    'modules/aws-environment/lambdas.tf' \
    'environment/qa/data.tf' \
    'environment/qa/outputs.tf' \
    'environment/qa/versions.tf'

  #
  # Test Global ENVs changes
  #

  expected='--config-file=.tfsec.json --force-all-dirs --exclude-downloaded-modules --concise-output --config-file=__GIT_WORKING_DIR__/.tfsec.json'
  assertEquals "ARGS -" "$expected" "${ARGS[*]}"
  # Extra space for `-h`
  expected="'.totalHourlyCost >= 0.1';  \".totalHourlyCost|tonumber > 1\";  \".projects[].diff.totalMonthlyCost|tonumber!=10000\";  [.projects[].diff.totalMonthlyCost | select (.!=null) | tonumber] | add > 1000; --retry-once-with-cleanup=true; --retry-once-with-cleanup=true;"
  assertEquals "HOOK_CONFIG -" "$expected" "${HOOK_CONFIG[*]}"
  # Extra space for `-i`
  expected='-get=true -get=true  -upgrade'
  assertEquals "TF_INIT_ARGS -" "$expected" "${TF_INIT_ARGS[*]}"
  # Extra space for `-e`
  expected='AWS_DEFAULT_REGION="us-west-2" AWS_ACCESS_KEY_ID="anaccesskey"  AWS_SECRET_ACCESS_KEY="asecretkey"'
  assertEquals "ENV_VARS -" "$expected" "${ENV_VARS[*]}"

  expected='environment/qa/backends.tf environment/qa/main.tf modules/aws-environment/lambdas.tf environment/qa/data.tf environment/qa/outputs.tf environment/qa/versions.tf'
  assertEquals "FILES -" "$expected" "${FILES[*]}"
}

# Load shUnit2. File populated to PATH from https://github.com/kward/shunit2
. shunit2
