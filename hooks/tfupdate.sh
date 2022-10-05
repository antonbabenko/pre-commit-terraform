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
  # JFYI: suppress color for `tfupdate` is N/A`

  # shellcheck disable=SC2153 # False positive
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
  # shellcheck disable=SC2034 # Unused var.
  local -r dir_path="$1"
  shift
  local -a -r args=("$@")

  local expand_args=()

  while read -r -d '' ARG; do
    expand_args+=("$ARG")
  done < <(echo "${args[@]}" | xargs printf '%s\0')

  # pass the arguments to hook
  tfupdate "${expand_args[@]}" .

  # return exit code to common::per_dir_hook
  local exit_code=$?
  return $exit_code
}

#######################################################################
# Unique part of `common::per_dir_hook`. The function is executed one time
# in the root git repo
# Arguments:
#   args (string with array) arguments that configure wrapped tool behavior
#######################################################################
function run_hook_on_whole_repo {
  local -a -r args=("$@")

  local expand_args=()

  while read -r -d '' ARG; do
    expand_args+=("$ARG")
  done < <(echo "${args[@]}" | xargs printf '%s\0')

  # pass the arguments to hook
  tfupdate "${expand_args[@]}" .

  # return exit code to common::per_dir_hook
  local exit_code=$?
  return $exit_code
}

[ "${BASH_SOURCE[0]}" != "$0" ] || main "$@"
