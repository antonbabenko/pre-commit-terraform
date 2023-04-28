#!/usr/bin/env bash

set -eo pipefail

# globals variables
# shellcheck disable=SC2155 # No way to assign to readonly variable in separate lines
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=_common.sh
. "$SCRIPT_DIR/_common.sh"

function main {
  common::initialize "$SCRIPT_DIR"
  common::parse_cmdline "$@"
  common::export_provided_env_vars "${ENV_VARS[@]}"
  common::parse_and_export_env_vars
  # Support for setting PATH to repo root.
  for i in "${!ARGS[@]}"; do
    ARGS[i]=${ARGS[i]/__GIT_WORKING_DIR__/$(pwd)\/}
  done
  # JFYI: tflint color already suppressed via PRE_COMMIT_COLOR=never

  # Run `tflint --init` for check that plugins installed.
  # It should run once on whole repo.
  {
    TFLINT_INIT=$(tflint --init "${ARGS[@]}" 2>&1) 2> /dev/null &&
      common::colorify "green" "Command 'tflint --init' successfully done:" &&
      echo -e "${TFLINT_INIT}\n\n\n"
  } || {
    local exit_code=$?
    common::colorify "red" "Command 'tflint --init' failed:"
    echo "${TFLINT_INIT}"
    return ${exit_code}
  }

  common::per_dir_hook "$HOOK_ID" "${#ARGS[@]}" "${ARGS[@]}" "${FILES[@]}"
}

#######################################################################
# Unique part of `common::per_dir_hook`. The function is executed in loop
# on each provided dir path. Run wrapped tool with specified arguments
# Arguments:
#   dir_path (string) PATH to dir relative to git repo root.
#     Can be used in error logging
#   args (array) arguments that configure wrapped tool behavior
# Outputs:
#   If failed - print out hook checks status
#######################################################################
function per_dir_hook_unique_part {
  local -r dir_path="$1"
  shift
  local -a -r args=("$@")

  TFLINT_OUTPUT=$(tflint "${args[@]}" 2>&1)
  local exit_code=$?

  if [ $exit_code -ne 0 ]; then
    common::colorify "yellow" "TFLint in $dir_path/:"
    echo "$TFLINT_OUTPUT"
  fi

  # return exit code to common::per_dir_hook
  return $exit_code
}

[ "${BASH_SOURCE[0]}" != "$0" ] || main "$@"
