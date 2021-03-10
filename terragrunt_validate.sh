#!/usr/bin/env bash

set -eo pipefail

main() {
  initialize_
  parse_cmdline_ "$@"
  terragrunt_validate_
}

to_abs_path() {
    local target="$1"

    if [ "$target" == "." ]; then
        echo "$(pwd)"
    elif [ "$target" == ".." ]; then
        echo "$(dirname "$(pwd)")"
    else
        echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
    fi
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
  argv=$(getopt -o x: --long exclude-path: -- "$@") || return
  eval "set -- $argv"

  for argv; do
    case $argv in
      -x | --exclude-path)
        shift
        EXCLUDED_PATHS+=("$(to_abs_path $1)")
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

terragrunt_validate_() {
  declare -a paths

  local index=0
  local error=0
  local file_with_path

  for file_with_path in "${FILES[@]}"; do
    file_with_path="${file_with_path// /__REPLACED__SPACE__}"

    if [[ "${EXCLUDED_PATHS[@]}" =~ "$(dirname "$file_with_path")" ]]; then
      continue
    fi

    paths[index]=$(dirname "$file_with_path")
    ((index += 1))
  done

  for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
    path_uniq="${path_uniq//__REPLACED__SPACE__/ }"

    pushd "$path_uniq" > /dev/null

    set +e
    validate_output=$(terragrunt validate 2>&1)
    validate_code=$?
    set -e

    if [[ $validate_code != 0 ]]; then
      error=1
      echo "Validation failed: $path_uniq"
      echo "$validate_output"
      echo
    fi

    popd > /dev/null
  done
}
