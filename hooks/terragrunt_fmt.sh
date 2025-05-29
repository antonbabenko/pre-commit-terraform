#!/usr/bin/env bash
set -eo pipefail

# globals variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
# shellcheck source=_common.sh
. "$SCRIPT_DIR/_common.sh"

#######################################################################
# Get the appropriate terragrunt format command based on version
# Outputs:
#   terragrunt format command (either "hclfmt" or "hcl format")
#######################################################################
function get_terragrunt_format_cmd {
  local terragrunt_version
  local major minor patch

  # Get terragrunt version, extract the version number
  terragrunt_version=$(terragrunt --version 2>/dev/null | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1 | sed 's/^v//')

  if [[ -z "$terragrunt_version" ]]; then
    # If version detection fails, default to newer command
    echo "hcl format"
    return
  fi

  # Parse version components
  IFS='.' read -r major minor patch <<< "$terragrunt_version"

  # Compare version: if < 0.78, use hclfmt, otherwise use hcl format
  if [[ $major -eq 0 && $minor -lt 78 ]]; then
    echo "hclfmt"
  else
    echo "hcl format"
  fi
}

function main {
  common::initialize "$SCRIPT_DIR"
  common::parse_cmdline "$@"
  common::export_provided_env_vars "${ENV_VARS[@]}"
  common::parse_and_export_env_vars
  # JFYI: `terragrunt hcl format` color already suppressed via PRE_COMMIT_COLOR=never

  # shellcheck disable=SC2153 # False positive
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
#   parallelism_disabled (bool) if true - skip lock mechanism
#   args (array) arguments that configure wrapped tool behavior
#   tf_path (string) PATH to Terraform/OpenTofu binary
# Outputs:
#   If failed - print out hook checks status
#######################################################################
function per_dir_hook_unique_part {
  # shellcheck disable=SC2034 # Unused var.
  local -r dir_path="$1"
  # shellcheck disable=SC2034 # Unused var.
  local -r change_dir_in_unique_part="$2"
  # shellcheck disable=SC2034 # Unused var.
  local -r parallelism_disabled="$3"
  # shellcheck disable=SC2034 # Unused var.
  local -r tf_path="$4"
  shift 4
  local -a -r args=("$@")

  # Get the appropriate terragrunt format command
  local format_cmd
  format_cmd=$(get_terragrunt_format_cmd)

  # pass the arguments to hook
  terragrunt "$format_cmd" "${args[@]}"

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

  # Get the appropriate terragrunt format command
  local format_cmd
  format_cmd=$(get_terragrunt_format_cmd)

  # pass the arguments to hook
  terragrunt "$format_cmd" "$(pwd)" "${args[@]}"

  # return exit code to common::per_dir_hook
  local exit_code=$?
  return $exit_code
}

[ "${BASH_SOURCE[0]}" != "$0" ] || main "$@"
