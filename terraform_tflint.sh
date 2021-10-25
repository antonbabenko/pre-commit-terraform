#!/usr/bin/env bash

set -eo pipefail

function main {
  common::initialize
  common::parse_cmdline "$@"
  #! Avoiding breaking changes crutch. Will be simplified on
  #! https://github.com/antonbabenko/pre-commit-terraform/issues/262
  crutch="$(echo "${ARGS[*]}" | grep -oe '--config=/' || exit 0)"
  if [ "$crutch" != "" ]; then
    ARGS="${ARGS[*]}"
  else
    # Support for setting relative PATH to config.
    ARGS=${ARGS[*]/--config=/--config=$(pwd)\/}
  fi

  tflint_ "$ARGS" "${FILES[*]}"
}

function common::initialize {
  local SCRIPT_DIR
  # get directory containing this script
  SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

  # source getopt function
  # shellcheck source=lib_getopt
  . "$SCRIPT_DIR/lib_getopt"
}

# common global arrays.
# Populated in `parse_cmdline` and can used in hooks functions
declare -a ARGS=()
declare -a HOOK_CONFIG=()
declare -a FILES=()
function common::parse_cmdline {
  local argv
  argv=$(getopt -o a:,h: --long args:,hook-config: -- "$@") || return
  eval "set -- $argv"

  for argv; do
    case $argv in
      -a | --args)
        shift
        #! Avoiding breaking changes crutch. Will be removed in
        #! https://github.com/antonbabenko/pre-commit-terraform/issues/262
        expanded_arg="${1//__GIT_WORKING_DIR__/$PWD}"
        ARGS+=("$expanded_arg")
        # ARGS+=("$1")
        shift
        ;;
      -h | --hook-config)
        shift
        HOOK_CONFIG+=("$1;")
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

function tflint_ {
  local args
  read -r -a args <<< "$1"
  local files
  read -r -a files <<< "$2"

  local index=0
  for file_with_path in "${files[@]}"; do
    file_with_path="${file_with_path// /__REPLACED__SPACE__}"

    paths[index]=$(dirname "$file_with_path")

    ((index += 1))
  done

  for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
    path_uniq="${path_uniq//__REPLACED__SPACE__/ }"
    pushd "$path_uniq" > /dev/null

    # Print checked PATH **only** if TFLint have any messages
    # shellcheck disable=SC2091 # Suppress error output
    $(tflint "${args[@]}" 2>&1) 2> /dev/null || {
      echo >&2 -e "\033[1;31m\nERROR in $path_uniq/:\033[0m"
      tflint "${args[@]}"
    }

    popd > /dev/null
  done
}

[[ ${BASH_SOURCE[0]} != "$0" ]] || main "$@"
