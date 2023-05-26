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
  # JFYI: suppress color for `terraform providers lock` is N/A`

  # shellcheck disable=SC2153 # False positive
  common::per_dir_hook "$HOOK_ID" "${#ARGS[@]}" "${ARGS[@]}" "${FILES[@]}"
}

#######################################################################
# Check that all needed `h1` and `zh` SHAs are included in lockfile for
# each provider.
# Arguments:
#   platforms_count (number) How many `-platform` flags provided
# Outputs:
#   Return 0 when lockfile has all needed SHAs
#   Return 1-99 when lockfile is invalid
#   Return 100+ when not all SHAs found
#######################################################################
function lockfile_contains_all_needed_sha {
  local -r platforms_count="$1"

  local h1_counter="$platforms_count"
  local zh_counter=0

  # Reading each line
  while read -r line; do

    if [ "$(echo "$line" | grep -o '^"h1:')" == '"h1:' ]; then
      h1_counter=$((h1_counter - 1))
      continue
    fi

    if [ "$(echo "$line" | grep -o '^"zh:')" == '"zh:' ]; then
      zh_counter=0
      continue
    fi

    if [ "$(echo "$line" | grep -o ^provider)" == "provider" ]; then
      h1_counter="$platforms_count"
      zh_counter=$((zh_counter + 1))
      continue
    fi
    # No all SHA in provider found
    if [ "$(echo "$line" | grep -o '^}')" == "}" ]; then
      if [ "$h1_counter" -ge 1 ] || [ "$zh_counter" -ge 1 ]; then
        return $((100 + h1_counter + zh_counter))
      fi
    fi

    # lockfile always exists, because the hook triggered only on
    # `files: (\.terraform\.lock\.hcl)$`
  done < ".terraform.lock.hcl"

  # 0 if all OK, 2+ when invalid lockfile
  return $((h1_counter + zh_counter))
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
#   args (array) arguments that configure wrapped tool behavior
# Outputs:
#   If failed - print out hook checks status
#######################################################################
function per_dir_hook_unique_part {
  local -r dir_path="$1"
  # shellcheck disable=SC2034 # Unused var.
  local -r change_dir_in_unique_part="$2"
  shift 2
  local -a -r args=("$@")

  local platforms_count=0
  for arg in "${args[@]}"; do
    if [ "$(echo "$arg" | grep -o '^-platform=')" == "-platform=" ]; then
      platforms_count=$((platforms_count + 1))
    fi
  done

  local exit_code
  #
  # Get hook settings
  #
  local hook_mode

  IFS=";" read -r -a configs <<< "${HOOK_CONFIG[*]}"

  for c in "${configs[@]}"; do

    IFS="=" read -r -a config <<< "$c"
    key=${config[0]}
    value=${config[1]}

    case $key in
      --hook-mode)
        if [ "$hook_mode" ]; then
          common::colorify "yellow" 'Invalid hook config. Make sure that you specify not more than one "--hook-mode" flag'
          exit 1
        fi
        hook_mode=$value
        ;;
    esac
  done

  # only-check-is-current-lockfile-cross-platform
  # check-is-there-new-providers-added---run-terraform-init
  # always-regenerate-lockfile (default)
  [ ! "$hook_mode" ] && hook_mode="always-regenerate-lockfile"

  if [ "$hook_mode" == "only-check-is-current-lockfile-cross-platform" ] &&
    [ "$(lockfile_contains_all_needed_sha "$platforms_count")" == 0 ]; then
    exit 0
  fi

  common::terraform_init 'terraform providers lock' "$dir_path" || {
    exit_code=$?
    return $exit_code
  }

  if [ "$hook_mode" == "check-is-there-new-providers-added---run-terraform-init" ] &&
    [ "$(lockfile_contains_all_needed_sha "$platforms_count")" == 0 ]; then
    exit 0
  fi

  # pass the arguments to hook
  terraform providers lock "${args[@]}"

  # return exit code to common::per_dir_hook
  exit_code=$?
  return $exit_code
}

[ "${BASH_SOURCE[0]}" != "$0" ] || main "$@"
