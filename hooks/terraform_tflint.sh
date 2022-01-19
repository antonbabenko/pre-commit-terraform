#!/usr/bin/env bash

set -eo pipefail

# globals variables
# hook ID, see `- id` for details in .pre-commit-hooks.yaml file
readonly HOOK_ID='terraform_tflint'
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
  common::per_dir_hook "$ARGS" "$HOOK_ID" "${FILES[@]}"
}

#######################################################################
# Unique part of `common::per_dir_hook`. The function is executed in loop
# on each provided dir path. Run wrapped tool with specified arguments
# Arguments:
#   args (string with array) arguments that configure wrapped tool behavior
#   dir_path (string) PATH to dir relative to git repo root.
#     Can be used in error logging
# Outputs:
#   If failed - print out hook checks status
#######################################################################
function per_dir_hook_unique_part {
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
