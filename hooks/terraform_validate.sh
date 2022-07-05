#!/usr/bin/env bash
set -eo pipefail

# globals variables
# shellcheck disable=SC2155 # No way to assign to readonly variable in separate lines
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=_common.sh
. "$SCRIPT_DIR/_common.sh"

# `terraform validate` requires this env variable to be set
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-east-1}

function main {
  common::initialize "$SCRIPT_DIR"
  parse_cmdline_ "$@"
  common::parse_and_export_env_vars

  # Export provided env var K/V pairs to environment
  local var var_name var_value
  for var in "${ENVS[@]}"; do
    var_name="${var%%=*}"
    var_value="${var#*=}"
    # shellcheck disable=SC2086
    export $var_name="$var_value"
  done

  # shellcheck disable=SC2153 # False positive
  common::per_dir_hook "${ARGS[*]}" "$HOOK_ID" "${FILES[@]}"
}

#######################################################################
# Parse args and filenames passed to script and populate respective
# global variables with appropriate values
# Globals (init and populate):
#   ARGS (array) arguments that configure wrapped tool behavior
#   HOOK_CONFIG (array) arguments that configure hook behavior
#   INIT_ARGS (array) arguments to `terraform init` command
#   ENVS (array) environment variables that will be used with
#     `terraform` commands
#   FILES (array) filenames to check
# Arguments:
#   $@ (array) all specified in `hooks.[].args` in
#     `.pre-commit-config.yaml` and filenames.
#######################################################################
function parse_cmdline_ {
  declare argv
  argv=$(getopt -o e:i:a: --long envs:,init-args:,args: -- "$@") || return
  eval "set -- $argv"

  for argv; do
    case $argv in
      -a | --args)
        shift
        ARGS+=("$1")
        shift
        ;;
      -h | --hook-config)
        shift
        HOOK_CONFIG+=("$1;")
        shift
        ;;
      -i | --init-args)
        shift
        INIT_ARGS+=("$1")
        shift
        ;;
      -e | --envs)
        shift
        ENVS+=("$1")
        shift
        ;;
      --)
        shift
        FILES=("$@")
        break
        ;;
    esac
  done
}

#######################################################################
# Unique part of `common::per_dir_hook`. The function is executed in loop
# on each provided dir path. Run wrapped tool with specified arguments
# 1. Check if `.terraform` dir exists and if not - run `terraform init`
# 2. Run `terraform validate`
# 3. If at least 1 check failed - change the exit code to non-zero
# Arguments:
#   args (string with array) arguments that configure wrapped tool behavior
#   dir_path (string) PATH to dir relative to git repo root.
#     Can be used in error logging
#   ENVS (array) environment variables that will be used with
#     `terraform` commands
# Outputs:
#   If failed - print out hook checks status
#######################################################################
function per_dir_hook_unique_part {
  local -r args="$1"
  local -r dir_path="$2"

  local exit_code
  local validate_output

  common::terraform_init 'terraform validate' "$dir_path" || {
    exit_code=$?
    return $exit_code
  }

  # pass the arguments to hook
  # shellcheck disable=SC2068 # hook fails when quoting is used ("$arg[@]")
  validate_output=$(terraform validate ${args[@]} 2>&1)
  exit_code=$?

  if [ $exit_code -ne 0 ]; then
    common::colorify "red" "Validation failed: $dir_path"
    echo -e "$validate_output\n\n"
  fi

  # return exit code to common::per_dir_hook
  return $exit_code
}

# global arrays
declare -a ENVS

[ "${BASH_SOURCE[0]}" != "$0" ] || main "$@"
