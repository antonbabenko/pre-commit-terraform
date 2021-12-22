#!/usr/bin/env bash

set -eo pipefail

function main {
  common::initialize
  common::parse_cmdline "$@"
  checkov_ "${ARGS[*]}" "${FILES[@]}"
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
        FILES=("$@")
        break
        ;;
    esac
  done
}

function checkov_ {
  local -r args="$1"
  shift 1
  local -a -r files=("$@")

  # consume modified files passed from pre-commit so that
  # checkov runs against only those relevant directories
  local index=0
  for file_with_path in "${files[@]}"; do
    file_with_path="${file_with_path// /__REPLACED__SPACE__}"

    paths[index]=$(dirname "$file_with_path")

    ((index += 1))
  done

  # allow checkov to continue if exit_code is greater than 0
  # preserve errexit status
  shopt -qo errexit && ERREXIT_IS_SET=true
  set +e
  checkov_final_exit_code=0

  # for each path run checkov
  for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
    path_uniq="${path_uniq//__REPLACED__SPACE__/ }"
    pushd "$path_uniq" > /dev/null

    # pass git root dir, if args not specified
    if [ -z "$args" ]; then
      checkov -d .
    else
      checkov "${args[@]}"
    fi

    local exit_code=$?
    if [ $exit_code != 0 ]; then
      checkov_final_exit_code=$exit_code
    fi

    popd > /dev/null
  done

  # restore errexit if it was set before the "for" loop
  [[ $ERREXIT_IS_SET ]] && set -e
  # return the checkov final exit_code
  exit $checkov_final_exit_code
}

[[ ${BASH_SOURCE[0]} != "$0" ]] || main "$@"
