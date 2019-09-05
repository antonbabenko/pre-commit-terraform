#!/usr/bin/env bash
set -e

declare -a paths

index=0

for file_with_path in "$@"; do
  paths[index]=$(dirname "$file_with_path")
  (( index++ ))
done

for path_uniq in "${paths[@]}"; do
  pushd "$path_uniq" > /dev/null
  terragrunt hclfmt
  popd > /dev/null
done
