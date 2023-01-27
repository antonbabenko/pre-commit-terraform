#!/usr/bin/env bash

function oneTimeSetUp {
  # Load include to test.
  . ../../hooks/_common.sh
}

function test__HOOK_ID {
  assertEquals "_common_test" $HOOK_ID
}

# function test__initialize {
#   Nothing to test
# }

function test__parse_cmdline {

  common::parse_cmdline "args=ololo=123"


  assertEquals "ARGS: " "_" "${ARGS[$@]}"
  # assertEquals "HOOK_CONFIG: " "[dd]" "${HOOK_CONFIG[$@]}"

}




# Load shUnit2. File populated to PATH from https://github.com/kward/shunit2
. shunit2

