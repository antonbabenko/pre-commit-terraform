#!/usr/bin/env bash
set -e

main() {
  initialize_
  declare argv
  argv=$(getopt -o a: --long args: -- "$@") || return
  eval "set -- $argv"

  declare args 
  declare -a files

  for argv; do
    case $argv in
      -a | --args)
        shift
        args="$1"
        shift
        ;;
      --)
        shift
        read -r -a files <<<"$@"
        break
        ;;
    esac
  done

  tflint_ "$args" "${files[@]}"
}

initialize_() {
  # get directory containing this script
  local dir
  local source
  source="${BASH_SOURCE[0]}"
  while [[ -h $source ]]; do # resolve $source until the file is no longer a symlink
    dir="$( cd -P "$( dirname "$source" )" >/dev/null && pwd )"
    source="$(readlink "$source")"
     # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    [[ $source != /* ]] && source="$dir/$source"
  done
  _SCRIPT_DIR="$(dirname "$source")"

  # source getopt function
  # shellcheck source=lib_getopt
  . "$_SCRIPT_DIR/lib_getopt"
}

tflint_() {
  for file_with_path in "${files[@]}"; do
    file_with_path="${file_with_path// /__REPLACED__SPACE__}"

    paths[index]=$(dirname "$file_with_path")

    ((index+=1))
  done

  for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
    path_uniq="${path_uniq//__REPLACED__SPACE__/ }"

    pushd "$path_uniq" > /dev/null
    tflint "$args"
    popd > /dev/null
  done
}

[[ ${BASH_SOURCE[0]} != "$0" ]] || main "$@"
