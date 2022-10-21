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
  common::parse_cmdline "$@"
  common::export_provided_env_vars "${ENV_VARS[@]}"
  common::parse_and_export_env_vars

  # Suppress terraform validate color
  if [ "$PRE_COMMIT_COLOR" = "never" ]; then
    ARGS+=("-no-color")
  fi
  # shellcheck disable=SC2153 # False positive
  common::per_dir_hook "$HOOK_ID" "${#ARGS[@]}" "${ARGS[@]}" "${FILES[@]}"
}

#######################################################################
# Unique part of `common::per_dir_hook`. The function is executed in loop
# on each provided dir path. Run wrapped tool with specified arguments
# 1. Check if `.terraform` dir exists and if not - run `terraform init`
# 2. Run `terraform validate`
# 3. If at least 1 check failed - change the exit code to non-zero
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

  local exit_code

  #
  # Get hook settings
  #
  local retry_once_with_cleanup=false

  IFS=";" read -r -a configs <<< "${HOOK_CONFIG[*]}"

  for c in "${configs[@]}"; do

    IFS="=" read -r -a config <<< "$c"
    key=${config[0]}
    value=${config[1]}

    case $key in
      --retry-once-with-cleanup)
        retry_once_with_cleanup=$value
        ;;
    esac
  done

  function do_validate {

    local exit_code
    local validate_output

    common::terraform_init 'terraform validate' "$dir_path" || {
      exit_code=$?
      return $exit_code
    }

    # pass the arguments to hook
    validate_output=$(terraform validate "${args[@]}" 2>&1)
    exit_code=$?

    return $exit_code
  }

  do_validate
  exit_code=$?

  if [ $exit_code -ne 0 ] && [ "$retry_once_with_cleanup" = true ]; then
    if [ -d .terraform ]; then
      # Will only be displayed if validation fails again.
      common::colorify "yellow" "Validation failed. Re-initialising: $dir_path"
      rm -r .terraform
      do_validate
      exit_code=$?
    fi
  fi

  if [ $exit_code -ne 0 ]; then
    common::colorify "red" "Validation failed: $dir_path"
    echo -e "$validate_output\n\n"
  fi

  # return exit code to common::per_dir_hook
  return $exit_code
}

[ "${BASH_SOURCE[0]}" != "$0" ] || main "$@"
