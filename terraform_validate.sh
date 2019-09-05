#!/usr/bin/env bash
set -e

declare -a paths

index=0
error=0

for file_with_path in "$@"; do
  paths[index]=$(dirname "$file_with_path")
  (( ++index ))
done

for path_uniq in "${paths[@]}"; do
  if ! terraform validate "$path_uniq"; then
    error=1
    echo
    echo "Failed path: $path_uniq"
    echo "================================"
  fi
done

if [[ "${error}" -ne 0 ]]; then
  exit 1
fi
