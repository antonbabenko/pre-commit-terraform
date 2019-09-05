#!/usr/bin/env bash
set -e

declare -a paths

index=0

if [[ $1 =~ -var-file=.+ ]]; then
  argument=$1
  shift
fi

for file_with_path in "$@"; do
  paths[index]=$(dirname "$file_with_path")
  ((++index))
done

for path_uniq in "${paths[@]}"; do
  pushd "$path_uniq" >/dev/null
  tflint --deep ${argument:+"$argument"}
  popd >/dev/null
done
