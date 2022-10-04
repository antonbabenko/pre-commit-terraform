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
  shift 1
  declare -a -r args=("$@")

  local expand_args=()
  for arg in "${args[@]}"; do
    if [[ "$arg" == *'"'* ]]; then
      elements=($arg)
      unset start
      unset end
      unset quoted_var

      for i in "${!elements[@]}"; do

        if [[ "${elements[i]}" =~ ^\" ]]; then
          start=$i
        fi

        if [[ "${elements[i]}" =~ \"$ ]]; then
          end=$i
        fi
      done

      for i in $(seq 0 $((start - 1))); do
        expand_args+=("${elements[i]}")
      done

      for i in $(seq "$start" "$end"); do
        quoted_var+="${elements[i]} "
      done
      quoted_var2=${quoted_var#'"'}
      quoted_var2=${quoted_var2%'" '}
      expand_args+=("$quoted_var2")

      for i in $(seq $((end + 1)) $((${#elements[@]} - 1))); do
        expand_args+=("${elements[i]}")
      done

    elif
      [[ "$arg" == *"'"* ]]
    then
      # Mostly copy-paste

      elements=($arg)
      unset start
      unset end
      unset quoted_var

      for i in "${!elements[@]}"; do

        if [[ "${elements[i]}" =~ ^\' ]]; then
          start=$i
        fi

        if [[ "${elements[i]}" =~ \'$ ]]; then
          end=$i
        fi
      done

      for i in $(seq 0 $((start - 1))); do
        expand_args+=("${elements[i]}")
      done

      for i in $(seq "$start" "$end"); do
        quoted_var+="${elements[i]} "
      done
      quoted_var2=${quoted_var#"'"}
      quoted_var2=${quoted_var2%"' "}
      expand_args+=("$quoted_var2")

      for i in $(seq $((end + 1)) $((${#elements[@]} - 1))); do
        expand_args+=("${elements[i]}")
      done

    else
      #
      expand_args+=($arg)
    fi
  done

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
  local -r args="$1"
  # pass the arguments to hook
  # shellcheck disable=SC2068 # hook fails when quoting is used ("$arg[@]")
  # shellcheck disable=SC2048 # Use "${array[@]}" (with quotes) to prevent whitespace problems.
  # shellcheck disable=SC2086 #  Double quote to prevent globbing and word splitting.
  tfupdate ${args[*]} --recursive .

  # return exit code to common::per_dir_hook
  local exit_code=$?
  return $exit_code
}

[ "${BASH_SOURCE[0]}" != "$0" ] || main "$@"
