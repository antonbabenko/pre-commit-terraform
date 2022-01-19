#!/usr/bin/env bash
set -eo pipefail

# globals variables
# hook ID, see `- id` for details in .pre-commit-hooks.yaml file
# shellcheck disable=SC2034 # Unused var.
readonly HOOK_ID='terraform_fmt'
# shellcheck disable=SC2155 # No way to assign to readonly variable in separate lines
readonly SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=_common.sh
. "$SCRIPT_DIR/_common.sh"

function main {
  common::initialize "$SCRIPT_DIR"
  common::parse_cmdline "$@"
  # shellcheck disable=SC2153 # False positive
  terraform_fmt_ "${ARGS[*]}" "${FILES[@]}"
}

#######################################################################
# Hook execution boilerplate logic which is common to hooks, that run
# on per dir basis. Little bit extended than `common::per_dir_hook`
# 1. Because hook runs on whole dir, reduce file paths to uniq dir paths
# (unique) 1.1. Collect paths to *.tfvars files in a separate variable
# 2. Run for each dir `per_dir_hook_unique_part`, on all paths
# (unique) 2.1. Run `terraform fmt` on each *.tfvars file
# 2.2. If at least 1 check failed - change exit code to non-zero
# 3. Complete hook execution and return exit code
# Arguments:
#   args (string with array) arguments that configure wrapped tool behavior
#   files (array) filenames to check
#######################################################################
function terraform_fmt_ {
  local -r args="$1"
  shift 1
  local -a -r files=("$@")
  # consume modified files passed from pre-commit so that
  # hook runs against only those relevant directories
  local index=0
  for file_with_path in "${files[@]}"; do
    file_with_path="${file_with_path// /__REPLACED__SPACE__}"

    dir_paths[index]=$(dirname "$file_with_path")
    # TODO Unique part
    if [[ "$file_with_path" == *".tfvars" ]]; then
      tfvars_files+=("$file_with_path")
    fi
    #? End for unique part
    ((index += 1))
  done

  # preserve errexit status
  shopt -qo errexit && ERREXIT_IS_SET=true
  # allow hook to continue if exit_code is greater than 0
  set +e
  local final_exit_code=0

  # run hook for each path
  for dir_path in $(echo "${dir_paths[*]}" | tr ' ' '\n' | sort -u); do
    dir_path="${dir_path//__REPLACED__SPACE__/ }"
    pushd "$dir_path" > /dev/null || continue

    per_dir_hook_unique_part "$args" "$dir_path"

    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
      final_exit_code=$exit_code
    fi

    popd > /dev/null
  done

  # TODO: Unique part
  # terraform.tfvars are excluded by `terraform fmt`
  for tfvars_file in "${tfvars_files[@]}"; do
    tfvars_file="${tfvars_file//__REPLACED__SPACE__/ }"

    terraform fmt "${ARGS[@]}" "$tfvars_file"
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
      final_exit_code=$exit_code
    fi
  done
  #? End for unique part
  # restore errexit if it was set before the "for" loop
  [[ $ERREXIT_IS_SET ]] && set -e
  # return the hook final exit_code
  exit $final_exit_code

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

  # pass the arguments to hook
  # shellcheck disable=SC2068 # hook fails when quoting is used ("$arg[@]")
  terraform fmt ${args[@]}

  # return exit code to common::per_dir_hook
  local exit_code=$?
  return $exit_code
}

[ "${BASH_SOURCE[0]}" != "$0" ] || main "$@"
