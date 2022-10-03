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
  common::per_dir_hook "${ARGS[*]}" "$HOOK_ID" "${FILES[@]}"
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
  # shellcheck disable=SC2034 # Unused var.
  local -r dir_path="$2"
  #
  # Expand array, but not substrings inside it.
  # If no substrings - execute hook.
  #
  if [[ "$args" == *'"'* ]]; then
    IFS='"' read -r expand_args version version2 <<< "$args"
  elif [[ "$args" == *"'"* ]]; then
    IFS="'" read -r expand_args version version2 <<< "$args"
  else
    # shellcheck disable=SC2068 # hook fails when quoting is used ("$arg[@]")
    tfupdate ${args[@]} .
    # return exit code to common::per_dir_hook
    local exit_code=$?
    return $exit_code
  fi

  # Check that user pass vars to hook in right order.
  # If not - swap elements to right order.
  # Without this fix, wrong order make hook as PASSED for unknown reason.

  #   right order result:
  #     expand_args: provider aws --version
  #     version: ~> 4.2.0
  #     version2:
  #   wrong order result:
  #     expand_args: --version
  #     version: ~> 4.2.0
  #     version2: provider aws
  if [[ -n $version2 ]]; then
    expand_args="$version2 $expand_args"
  fi

  # pass the arguments to hook
  # shellcheck disable=SC2068 # hook fails when quoting is used ("$arg[@]")
  tfupdate ${expand_args[@]} "$version" .

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
  local -r args="$1"
  #
  # Expand array, but not substrings inside it.
  # If no substrings - execute hook.
  #
  if [[ "$args" == *'"'* ]]; then
    IFS='"' read -r expand_args version version2 <<< "$args"
  elif [[ "$args" == *"'"* ]]; then
    IFS="'" read -r expand_args version version2 <<< "$args"
  else
    # shellcheck disable=SC2068 # hook fails when quoting is used ("$arg[@]")
    tfupdate ${args[@]} --recursive .
    # return exit code to common::per_dir_hook
    local exit_code=$?
    return $exit_code
  fi

  # Check that user pass args to hook in right order.
  # If not - swap elements to right order.
  # Without this fix, wrong order make hook as PASSED for unknown reason.

  #   right order result:
  #     expand_args: provider aws --version
  #     version: ~> 4.2.0
  #     version2:
  #   wrong order result:
  #     expand_args: --version
  #     version: ~> 4.2.0
  #     version2: provider aws
  if [[ -n $version2 ]]; then
    expand_args="$version2 $expand_args"
  fi

  # pass the arguments to hook
  # shellcheck disable=SC2068 # hook fails when quoting is used ("$arg[@]")
  tfupdate ${expand_args[@]} "$version" --recursive .

  # return exit code to common::per_dir_hook
  local exit_code=$?
  return $exit_code
}

[ "${BASH_SOURCE[0]}" != "$0" ] || main "$@"
