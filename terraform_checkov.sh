#!/usr/bin/env bash

set -eo pipefail

main() {
  initialize_
  parse_cmdline_ "$@"
  checkov_
}

initialize_() {
  # get directory containing this script
  local dir
  local source
  source="${BASH_SOURCE[0]}"
  while [[ -L $source ]]; do # resolve $source until the file is no longer a symlink
    dir="$(cd -P "$(dirname "$source")" > /dev/null && pwd)"
    source="$(readlink "$source")"
    # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    [[ $source != /* ]] && source="$dir/$source"
  done
  _SCRIPT_DIR="$(dirname "$source")"

  # source getopt function
  # shellcheck source=lib_getopt
  . "$_SCRIPT_DIR/lib_getopt"
}

parse_cmdline_() {
  declare argv
  argv=$(getopt -o a: --long args: -- "$@") || return
  eval "set -- $argv"

  for argv; do
    case $argv in
      -a | --args)
        shift
        expanded_arg="${1//__GIT_WORKING_DIR__/$PWD}"
        ARGS+=("$expanded_arg")
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

checkov_() {
  local index=0
  for file_with_path in "${FILES[@]}"; do
    file_with_path="${file_with_path// /__REPLACED__SPACE__}"

    paths[index]=$(dirname "$file_with_path")

    ((index += 1))
  done
  set +e
  checkov_final_exit_code=0
  for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
    path_uniq="${path_uniq//__REPLACED__SPACE__/ }"

    # Print checked PATH **only** if Checkov have any messages
    # shellcheck disable=SC2091 # Suppress error output
    $(checkov "${ARGS[@]}" -d $path_uniq 2>&1) 2> /dev/null || {
      echo >&2 -e "\033[1;33m\nCheckov in $path_uniq/:\033[0m"
      checkov "${ARGS[@]}" -d $path_uniq
    }
    local exit_code=$?
    if [ $exit_code != 0 ]; then
      checkov_final_exit_code=$exit_code
    fi
  done
  set -e
  exit $checkov_final_exit_code
}

# global arrays
declare -a ARGS
declare -a FILES

[[ ${BASH_SOURCE[0]} != "$0" ]] || main "$@"
