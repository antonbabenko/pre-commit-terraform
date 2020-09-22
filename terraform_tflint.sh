#!/usr/bin/env bash

#set -eo pipefail
set -eo pipefail

main() {
  echo "===="
  echo "$@"

  initialize_
  parse_cmdline_ "$@"
  tflint_
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

  echo "fff"
  echo "${argv[@]}"
  echo "${argv}"
  for argv; do
    case $argv in
      -a | --args)
        shift
        expanded_arg="${1//__GIT_WORKING_DIR__/$PWD}"
#        echo "bbb=$expanded_arg"
        ARGS+=("$expanded_arg")
#        ARGS+=("$1")
        shift
        ;;
      --)
        shift
        FILES=("$@")
        break
        ;;
    esac
  done

  #  ARGS+=("--config=$PWD/.tflint.hcl")

}

tflint_() {
  local index=0
  for file_with_path in "${FILES[@]}"; do
    file_with_path="${file_with_path// /__REPLACED__SPACE__}"

    paths[index]=$(dirname "$file_with_path")

    ((index += 1))
  done

  #echo "ARGS====="
  #echo "${ARGS[@]}"

  for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
    path_uniq="${path_uniq//__REPLACED__SPACE__/ }"

    env

    pushd "$path_uniq" # > /dev/null
    tflint "${ARGS[@]}"
    popd > /dev/null
  done
}

# global arrays
declare -a ARGS
declare -a FILES

#echo "ABBBBBBSSSS="
#pwd

[[ ${BASH_SOURCE[0]} != "$0" ]] || main "$@"
