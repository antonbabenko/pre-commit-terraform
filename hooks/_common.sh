#!/usr/bin/env bash
set -eo pipefail

#######################################################################
# Init arguments parser
# Arguments:
#   script_dir - absolute path to hook dir location
#######################################################################
function common::initialize {
  local -r script_dir=$1
  # source getopt function
  # shellcheck source=../lib_getopt
  . "$script_dir/../lib_getopt"
}

#######################################################################
# Parse args and filenames passed to script and populate respective
# global variables with appropriate values
# Globals (init and populate):
#   ARGS (array) arguments that configure wrapped tool behavior
#   HOOK_CONFIG (array) arguments that configure hook behavior
#   FILES (array) filenames to check
# Arguments:
#   $@ (array) all specified in `hooks.[].args` in
#     `.pre-commit-config.yaml` and filenames.
#######################################################################
function common::parse_cmdline {
  # common global arrays.
  # Populated via `common::parse_cmdline` and can be used inside hooks' functions
  declare -g -a ARGS=() HOOK_CONFIG=() FILES=()

  local argv
  argv=$(getopt -o a:,h: --long args:,hook-config: -- "$@") || return
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
      --)
        shift
        # shellcheck disable=SC2034 # Variable is used
        FILES=("$@")
        break
        ;;
    esac
  done
}

#######################################################################
# Hook execution boilerplate logic which is common to hooks, that run
# on per dir basis.
# 1. Because hook runs on whole dir, reduce file paths to uniq dir paths
# 2. Run for each dir `per_dir_hook_unique_part`, on all paths
# 2.1. If at least 1 check failed - change exit code to non-zero
# 3. Complete hook execution and return exit code
# Arguments:
#   args (string with array) arguments that configure wrapped tool behavior
#   files (array) filenames to check
#######################################################################
function common::per_dir_hook {
  local -r args="$1"
  shift 1
  local -a -r files=("$@")

  # consume modified files passed from pre-commit so that
  # hook runs against only those relevant directories
  local index=0
  for file_with_path in "${files[@]}"; do
    file_with_path="${file_with_path// /__REPLACED__SPACE__}"

    dir_paths[index]=$(dirname "$file_with_path")

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

  # restore errexit if it was set before the "for" loop
  [[ $ERREXIT_IS_SET ]] && set -e
  # return the hook final exit_code
  exit $final_exit_code
}

#######################################################################
# Colorize provided string and print it out to stdout
# Environment variables:
#   PRE_COMMIT_COLOR (string) If set to `never` - do not colorize output
# Arguments:
#   COLOR (string) Color name that will be used to colorize
#   TEXT (string)
# Outputs:
#   Print out provided text to stdout
#######################################################################
function common::colorify {
  # shellcheck disable=SC2034
  local -r red="\e[0m\e[31m"
  # shellcheck disable=SC2034
  local -r green="\e[0m\e[32m"
  # shellcheck disable=SC2034
  local -r yellow="\e[0m\e[33m"
  # Color reset
  local -r RESET="\e[0m"

  # Params start #
  local COLOR="${!1}"
  local -r TEXT=$2
  # Params end #

  if [ "$PRE_COMMIT_COLOR" = "never" ]; then
    COLOR=$RESET
  fi

  echo -e "${COLOR}${TEXT}${RESET}"
}
