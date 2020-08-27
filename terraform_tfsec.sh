#!/usr/bin/env bash
set -euo pipefail

main() {
  initialize_
  parse_cmdline_ "$@"

  # Don't pass any files tfsec will recurse directories anyway.
  tfsec "$ARGS" .
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
        # ignore any parameters, as they're not used
        break
        ;;
    esac
  done
}

# global arrays
declare -a ARGS

[[ ${BASH_SOURCE[0]} != "$0" ]] || main "$@"
