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

  # Suppress tfsec color
  if [ "$PRE_COMMIT_COLOR" = "never" ]; then
    ARGS+=("--no-color")
  fi

  common::per_dir_hook "$HOOK_ID" "${#ARGS[@]}" "${ARGS[@]}" "${FILES[@]}"
}

#######################################################################
# Unique part of `common::per_dir_hook`. The function is executed in loop
# on each provided dir path. Run wrapped tool with specified arguments
# Arguments:
#   dir_path (string) PATH to dir relative to git repo root.
#     Can be used in error logging
#   change_dir_in_unique_part (string/false) Modifier which creates
#     possibilities to use non-common chdir strategies.
#     Availability depends on hook.
#   args (array) arguments that configure wrapped tool behavior
# Outputs:
#   If failed - print out hook checks status
#######################################################################
function per_dir_hook_unique_part {
  # shellcheck disable=SC2034 # Unused var.
  local -r dir_path="$1"
  # shellcheck disable=SC2034 # Unused var.
  local -r change_dir_in_unique_part="$2"
  shift 2
  local -a -r args=("$@")

  # pass the arguments to hook
  tfsec "${args[@]}"

  # return exit code to common::per_dir_hook
  local exit_code=$?
  return $exit_code
}

#######################################################################
# Unique part of `common::per_dir_hook`. The function is executed one time
# in the root git repo
# Arguments:
#   args (array) arguments that configure wrapped tool behavior
#######################################################################
function run_hook_on_whole_repo {
  local -a -r args=("$@")

  # pass the arguments to hook
  tfsec "$(pwd)" "${args[@]}"

  # return exit code to common::per_dir_hook
  local exit_code=$?
  return $exit_code
}

[ "${BASH_SOURCE[0]}" != "$0" ] || main "$@"
