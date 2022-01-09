#!/usr/bin/env bash

set -eo pipefail

# shellcheck disable=SC2155 # No way to assign to readonly variable in separate lines
readonly SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=_common.sh
. "$SCRIPT_DIR/_common.sh"

function main {
  common::initialize "$SCRIPT_DIR"
  common::parse_cmdline "$@"
  # Support for setting PATH to repo root.
  # shellcheck disable=SC2178 # It's the simplest syntax for that case
  ARGS=${ARGS[*]/__GIT_WORKING_DIR__/$(pwd)\/}
  # shellcheck disable=SC2128 # It's the simplest syntax for that case
  common::per_dir_hook "$ARGS" "${FILES[@]}"
}

function per_dir_hook_unique_part {
  # common logic located in common::per_dir_hook
  local -r args="$1"
  local -r dir_path="$2"

  # Print checked PATH **only** if TFLint have any messages
  # shellcheck disable=SC2091,SC2068 # Suppress error output
  $(tflint ${args[@]} 2>&1) 2> /dev/null || {
    common::colorify "yellow" "TFLint in $dir_path/:"

    # shellcheck disable=SC2068 # hook fails when quoting is used ("$arg[@]")
    tflint ${args[@]}
  }

  # return exit code to common::per_dir_hook
  local exit_code=$?
  return $exit_code
}

[ "${BASH_SOURCE[0]}" != "$0" ] || main "$@"
