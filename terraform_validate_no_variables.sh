#!/usr/bin/env bash
set -e

declare -a paths
index=0

for file_with_path in "$@"; do
  paths[index]=$(dirname "$file_with_path")
  let "index+=1"
done

for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
  pushd "$path_uniq" > /dev/null
  terraform validate -check-variables=false
  popd > /dev/null
done
