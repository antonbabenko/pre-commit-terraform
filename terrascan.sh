#!/usr/bin/env bash
set -eo pipefail

main() {
  initialize_
  parse_cmdline_ "$@"
  terrascan_
}

terrascan_() {
  # consume modified files passed from pre-commit so that
  # terrascan runs against only those relevant directories
  for file_with_path in "${FILES[@]}"; do
    file_with_path="${file_with_path// /__REPLACED__SPACE__}"
    paths[index]=$(dirname "$file_with_path")
    ((index++)) || true
  done

  # allow terrascan continue if exit_code greater than 0
  set +e
  terrascan_final_exit_code=0

  # for each path run terrascan
  for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
    path_uniq="${path_uniq//__REPLACED__SPACE__/ }"
    pushd "$path_uniq" > /dev/null

    # pass the arguments to terrascan
    # shellcheck disable=SC2068 # terrascan fails when is used "${ARGS[@]}"
    terrascan scan -i terraform ${ARGS[@]}

    local exit_code=$?
    if [ $exit_code != 0 ]; then
      terrascan_final_exit_code=$exit_code
    fi

    popd > /dev/null
  done

  # return the terrascan final exit_code
  set -e
  exit $terrascan_final_exit_code
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
        ARGS+=("$1")
        shift
        ;;
      --)
        shift
        FILES+=("$@")
        break
        ;;
    esac
  done
}

# global arrays
declare -a ARGS=()
declare -a FILES=()

[[ ${BASH_SOURCE[0]} != "$0" ]] || main "$@"
