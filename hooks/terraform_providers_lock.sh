#!/usr/bin/env bash

set -eo pipefail

# globals variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
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

    if grep -Eq '^"h1:' <<< "$line"; then
      h1_counter=$((h1_counter - 1))
      continue
    fi

    if grep -Eq '^"zh:' <<< "$line"; then
      zh_counter=0
      continue
    fi

    if grep -Eq '^provider' <<< "$line"; then
      h1_counter="$platforms_count"
      zh_counter=$((zh_counter + 1))
      continue
    fi
    # Not all SHA inside provider lock definition block found
    if grep -Eq '^}' <<< "$line"; then
      if [ "$h1_counter" -ge 1 ] || [ "$zh_counter" -ge 1 ]; then
        # h1_counter can be less than 0, in the case when lockfile
        # contains more platforms than you currently specify
        # That's why here extra +50 - for safety reasons, to be sure
        # that error goes exactly from this part of the function
        return $((150 + h1_counter + zh_counter))
      fi
    fi

    # lockfile always exists, because the hook triggered only on
    # `files: (\.terraform\.lock\.hcl)$`
  done < ".terraform.lock.hcl"

  # When you specify `-platform``, but don't specify current platform -
  # platforms_count will be less than `h1:` headers`
  [ "$h1_counter" -lt 0 ] && h1_counter=0

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

  local platforms_count=0
  for arg in "${args[@]}"; do
    if grep -Eq '^-platform=' <<< "$arg"; then
      platforms_count=$((platforms_count + 1))
    fi
  done

  local exit_code
  #
  # Get hook settings
  #
  local mode

  IFS=";" read -r -a configs <<< "${HOOK_CONFIG[*]}"

  for c in "${configs[@]}"; do

    IFS="=" read -r -a config <<< "$c"
    key=${config[0]}
    value=${config[1]}

    case $key in
      --mode)
        if [ "$mode" ]; then
          common::colorify "yellow" 'Invalid hook config. Make sure that you specify not more than one "--mode" flag'
          exit 1
        fi
        mode=$value
        ;;
    esac
  done

  # Available options:
  #   only-check-is-current-lockfile-cross-platform (will be default)
  #   always-regenerate-lockfile
  # TODO: Remove in 2.0
  if [ ! "$mode" ]; then
    common::colorify "yellow" "DEPRECATION NOTICE: We introduced '--mode' flag for this hook.
Check migration instructions at https://github.com/antonbabenko/pre-commit-terraform#terraform_providers_lock
"
    common::terraform_init "$tf_path providers lock" "$dir_path" "$parallelism_disabled" "$tf_path" || {
      exit_code=$?
      return $exit_code
    }
  fi

  if [ "$mode" == "only-check-is-current-lockfile-cross-platform" ] &&
    lockfile_contains_all_needed_sha "$platforms_count"; then

    exit 0
  fi

  #? Don't require `tf init` for providers, but required `tf init` for modules
  #? Mitigated by `function match_validate_errors` from terraform_validate hook
  # pass the arguments to hook
  "$tf_path" providers lock "${args[@]}"

  # return exit code to common::per_dir_hook
  exit_code=$?
  return $exit_code
}

[ "${BASH_SOURCE[0]}" != "$0" ] || main "$@"
