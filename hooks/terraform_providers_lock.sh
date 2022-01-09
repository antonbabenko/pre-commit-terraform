#!/usr/bin/env bash

set -eo pipefail

# shellcheck disable=SC2155 # No way to assign to readonly variable in separate lines
readonly SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=_common.sh
. "$SCRIPT_DIR/_common.sh"

function main {
  common::initialize "$SCRIPT_DIR"
  common::parse_cmdline "$@"
  # shellcheck disable=SC2153 # False positive
  common::per_dir_hook "${ARGS[*]}" "${FILES[@]}"
}

function per_dir_hook_unique_part {
  # common logic located in common::per_dir_hook
  local -r args="$1"
  local -r dir_path="$2"

  if [ ! -d ".terraform" ]; then
    init_output=$(terraform init -backend=false 2>&1)
    init_code=$?

    if [ $init_code -ne 0 ]; then
      common::colorify "red" "Init before validation failed: $dir_path"
      common::colorify "red" "$init_output"
      exit $init_code
    fi
  fi

  # pass the arguments to hook
  # shellcheck disable=SC2068 # hook fails when quoting is used ("$arg[@]")
  terraform providers lock ${args[@]}

  # return exit code to common::per_dir_hook
  local exit_code=$?
  return $exit_code
}

[ "${BASH_SOURCE[0]}" != "$0" ] || main "$@"
