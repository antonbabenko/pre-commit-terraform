#!/usr/bin/env bash
set -eo pipefail

# globals variables
# hook ID, see `- id` for details in .pre-commit-hooks.yaml file
# shellcheck disable=SC2034 # Unused var.
readonly HOOK_ID='terraform_validate'
# shellcheck disable=SC2155 # No way to assign to readonly variable in separate lines
readonly SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=_common.sh
. "$SCRIPT_DIR/_common.sh"

# `terraform validate` requires this env variable to be set
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-east-1}

function main {
  common::initialize "$SCRIPT_DIR"
  parse_cmdline_ "$@"
  terraform_validate_
}

#######################################################################
# Parse args and filenames passed to script and populate respective
# global variables with appropriate values
# Globals (init and populate):
#   ARGS (array) arguments that configure wrapped tool behavior
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
# Wrapper around `terraform validate` tool that checks if code is valid
# 1. Export provided env var K/V pairs to environment
# 2. Because hook runs on whole dir, reduce file paths to uniq dir paths
# 3. In each dir that have *.tf files:
# 3.1. Check if `.terraform` dir exists and if not - run `terraform init`
# 3.2. Run `terraform validate`
# 3.3. If at least 1 check failed - change exit code to non-zero
# 4. Complete hook execution and return exit code
# Globals:
#   ARGS (array) arguments that configure wrapped tool behavior
#   INIT_ARGS (array) arguments for `terraform init` command`
#   ENVS (array) environment variables that will be used with
#     `terraform` commands
#   FILES (array) filenames to check
# Outputs:
#   If failed - print out hook checks status
#######################################################################
function terraform_validate_ {

  # Setup environment variables
  local var var_name var_value
  for var in "${ENVS[@]}"; do
    var_name="${var%%=*}"
    var_value="${var#*=}"
    # shellcheck disable=SC2086
    export $var_name="$var_value"
  done

  declare -a paths
  local index=0
  local error=0

  local file_with_path
  for file_with_path in "${FILES[@]}"; do
    file_with_path="${file_with_path// /__REPLACED__SPACE__}"

    paths[index]=$(dirname "$file_with_path")
    ((index += 1))
  done

  local dir_path
  for dir_path in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
    dir_path="${dir_path//__REPLACED__SPACE__/ }"

    if [[ -n "$(find "$dir_path" -maxdepth 1 -name '*.tf' -print -quit)" ]]; then

      pushd "$(realpath "$dir_path")" > /dev/null

      if [ ! -d .terraform ]; then
        set +e
        init_output=$(terraform init -backend=false "${INIT_ARGS[@]}" 2>&1)
        init_code=$?
        set -e

        if [ $init_code -ne 0 ]; then
          error=1
          echo "Init before validation failed: $dir_path"
          echo "$init_output"
          popd > /dev/null
          continue
        fi
      fi

      set +e
      validate_output=$(terraform validate "${ARGS[@]}" 2>&1)
      validate_code=$?
      set -e

      if [ $validate_code -ne 0 ]; then
        error=1
        echo "Validation failed: $dir_path"
        echo "$validate_output"
        echo
      fi

      popd > /dev/null
    fi
  done

  if [ $error -ne 0 ]; then
    exit 1
  fi
}

# global arrays
declare -a INIT_ARGS
declare -a ENVS

[ "${BASH_SOURCE[0]}" != "$0" ] || main "$@"
