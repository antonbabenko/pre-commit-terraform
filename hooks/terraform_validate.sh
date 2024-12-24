#!/usr/bin/env bash
set -eo pipefail

# globals variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
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
# Run `terraform validate` and match errors. Requires `jq`
# Arguments:
#   validate_output (string with json) output of `terraform validate` command
# Outputs:
#   Returns integer:
#    - 0 (no errors)
#    - 1 (matched errors; retry)
#    - 2 (no matched errors; do not retry)
#######################################################################
function match_validate_errors {
  local validate_output=$1

  local valid
  local summary

  valid=$(jq -rc '.valid' <<< "$validate_output")

  if [ "$valid" == "true" ]; then
    return 0
  fi

  # Parse error message for retry-able errors.
  while IFS= read -r error_message; do
    summary=$(jq -rc '.summary' <<< "$error_message")
    case $summary in
      "missing or corrupted provider plugins") return 1 ;;
      "Module source has changed") return 1 ;;
      "Module version requirements have changed") return 1 ;;
      "Module not installed") return 1 ;;
      "Could not load plugin") return 1 ;;
      "Missing required provider") return 1 ;;
      *"there is no package for"*"cached in .terraform/providers") return 1 ;;
    esac
  done < <(jq -rc '.diagnostics[]' <<< "$validate_output")

  return 2 # Some other error; don't retry
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
  local -r dir_path="$1"
  # shellcheck disable=SC2034 # Unused var.
  local -r change_dir_in_unique_part="$2"
  local -r parallelism_disabled="$3"
  local -r tf_path="$4"
  shift 4
  local -a -r args=("$@")

  local exit_code
  #
  # Get hook settings
  #
  local retry_once_with_cleanup

  IFS=";" read -r -a configs <<< "${HOOK_CONFIG[*]}"

  for c in "${configs[@]}"; do

    IFS="=" read -r -a config <<< "$c"
    key=${config[0]}
    value=${config[1]}

    case $key in
      --retry-once-with-cleanup)
        if [ "$retry_once_with_cleanup" ]; then
          common::colorify "yellow" 'Invalid hook config. Make sure that you specify not more than one "--retry-once-with-cleanup" flag'
          exit 1
        fi
        retry_once_with_cleanup=$value
        ;;
    esac
  done

  # First try `terraform validate` with the hope that all deps are
  # pre-installed. That is needed for cases when `.terraform/modules`
  # or `.terraform/providers` missed AND that is expected.
  "$tf_path" validate "${args[@]}" &> /dev/null && {
    exit_code=$?
    return $exit_code
  }

  # In case `terraform validate` failed to execute
  # - check is simple `terraform init` will help
  common::terraform_init "$tf_path validate" "$dir_path" "$parallelism_disabled" "$tf_path" || {
    exit_code=$?
    return $exit_code
  }

  if [ "$retry_once_with_cleanup" != "true" ]; then
    # terraform validate only
    validate_output=$("$tf_path" validate "${args[@]}" 2>&1)
    exit_code=$?
  else
    # terraform validate, plus capture possible errors
    validate_output=$("$tf_path" validate -json "${args[@]}" 2>&1)
    exit_code=$?

    # Match specific validation errors
    local -i validate_errors_matched
    match_validate_errors "$validate_output"
    validate_errors_matched=$?

    # Errors matched; Retry validation
    if [ "$validate_errors_matched" -eq 1 ]; then
      common::colorify "yellow" "Validation failed. Removing cached providers and modules from \"$dir_path/.terraform\" directory"
      # `.terraform` dir may comprise some extra files, like `environment`
      # which stores info about current TF workspace, so we can't just remove
      # `.terraform` dir completely.
      rm -rf .terraform/{modules,providers}/

      common::colorify "yellow" "Re-validating: $dir_path"

      common::terraform_init "$tf_path validate" "$dir_path" "$parallelism_disabled" "$tf_path" || {
        exit_code=$?
        return $exit_code
      }

      validate_output=$("$tf_path" validate "${args[@]}" 2>&1)
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
