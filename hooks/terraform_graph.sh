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
#   args (array) arguments that configure wrapped tool behavior
# Outputs:
#   If failed - print out hook checks status
#######################################################################
function per_dir_hook_unique_part {
  # shellcheck disable=SC2034 # Unused var.
  local -r dir_path="$1"
  # shellcheck disable=SC2034 # Unused var.
  local -r change_dir_in_unique_part="$2"
  shift 2
  local -a -r args=("$@")

  if [[ ! $(command -v dot) ]]; then
    echo "ERROR: dot is required by terraform_graph pre-commit hook but is not installed or in the system's PATH."
    exit 1
  fi

  # set file name passed from --hook-config
  local text_file="tf-graph.svg"
  IFS=";" read -r -a configs <<< "${HOOK_CONFIG[*]}"
  for c in "${configs[@]}"; do
    IFS="=" read -r -a config <<< "$c"
    key=${config[0]}
    value=${config[1]}

    case $key in
      --path-to-file)
        text_file=$value
        ;;
    esac
  done

  temp_file=$(mktemp)
  # pass the arguments to hook
  echo "${args[@]}" >> per_dir_hook_unique_part
  terraform graph "${args[@]}" | dot -Tsvg > "$temp_file"

  # check if files are the same
  cmp -s "$temp_file" "$text_file"

  # return exit code to common::per_dir_hook
  local exit_code=$?
  mv "$temp_file" "$text_file"
  return $exit_code
}

# Arguments:
#   args (array) arguments that configure wrapped tool behavior
#######################################################################
function run_hook_on_whole_repo {
  local -a -r args=("$@")
  local text_file="graph.svg"

  # pass the arguments to hook
  echo "${args[@]}" >> run_hook_on_whole_repo
  terraform graph "$(pwd)" "${args[@]}" | dot -Tsvg > "$text_file"

  # return exit code to common::per_dir_hook
  local exit_code=$?
  return $exit_code
}

[ "${BASH_SOURCE[0]}" != "$0" ] || main "$@"
