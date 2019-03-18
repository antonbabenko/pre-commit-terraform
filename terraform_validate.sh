#!/usr/bin/env bash

set -euo pipefail

# global vars
declare -A dirs_to_test
ERROR=0

# main code entrypoint
main() {
  get_uniq_dirs "$@"
  process_dirs
  exit "$ERROR"
}

# reduce the command line args to a list of valid, uniq dirs
get_uniq_dirs() {
  local file
  local abs_file
  local abs_dir
  for file in "$@" ; do
    # Check that file exists
    [[ -e $file ]] || continue

    # get absolute path
    abs_file="$(realpath "$file")"

    # test it's a dir
    if [[ -d $abs_file ]] ; then
      dirs_to_test["$abs_file"]=1
      continue
    fi

    # treat as a file
    abs_dir="$(dirname "$abs_file")"
    dirs_to_test["$abs_dir"]=1
  done
}
  
# validate one directory
test_dir() {
  local dir="$1" ; shift
  (
    cd "$dir"
    if stat -t -- *.tf >/dev/null 2>&1 ; then
      if ! terraform validate -check-variables=true ; then
        echo
        echo "Failed path: $dir"
        echo "================================"
        return 1
      fi
    fi
  )
}

# process each directory
process_dirs() {
  local dir
  for dir in "${!dirs_to_test[@]}"; do
    test_dir "$dir" || ERROR=1
  done
}

main "$@"
