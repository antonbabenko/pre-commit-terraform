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

  common::terraform_init 'terraform validate' "$dir_path" || {
    exit_code=$?
    return $exit_code
  }

  function do_validate {
    validate_output=$(terraform validate "${args[@]}" 2>&1)
    exit_code=$?
    return $exit_code
  }

  function parse_validate {
    # Requires jq
    local exit_code
    local validate_output
    local valid
    local summary

    validate_output=$(terraform validate -json "${args[@]}" 2>&1)
    exit_code=$?

    valid=$(jq -rc '.valid' <<< "$validate_output")

    if [ "$valid" == "true" ]; then
      return 0
    fi

    # Pretty-print error information
    jq '.diagnostics[]' <<< "$validate_output"

    # Parse error message, return code 10 to indicate a catch
    while IFS= read -r error_message; do
      summary=$(jq -rc '.summary' <<< "$error_message")
      case $summary in
        "missing or corrupted provider plugins")
          return 10
          ;;
        "Module source has changed")
          return 10
          ;;
        "Module version requirements have changed")
          return 10
          ;;
        "Module not installed")
          return 10
          ;;
      esac
    done < <(jq -rc '.diagnostics[]' <<< "$validate_output")
    # Return `terraform validate`'s original exit code
    # when `$summary` isn't covered by `case` block above
    return $exit_code
  }

  if [ "$retry_once_with_cleanup" == "true" ]; then
    parse_validate
    exit_code=$?
  else
    do_validate
    exit_code=$?
  fi

  if [ $exit_code -eq 10 ] && [ "$retry_once_with_cleanup" == "true" ]; then
    if [ -d .terraform ]; then
      # Will only be displayed if validation fails again.
      common::colorify "yellow" "Validation failed. Removing .terraform from: $dir_path"
      rm -rf .terraform
      common::colorify "yellow" "Re-validating: $dir_path"
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
