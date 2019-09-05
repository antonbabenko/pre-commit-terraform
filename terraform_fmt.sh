#!/usr/bin/env bash
set -e

declare -a paths
declare -a tfvars_files

index=0

if [[ $1 == "-ignore-tfvars" ]]; then
  argument=$1
  shift
fi

for file_with_path in "$@"; do
  paths[index]=$(dirname "$file_with_path")
  if [[ "$file_with_path" =~ .+\.tfvars ]]; then
    if [[ -z "$argument" ]]; then
      tfvars_files+=("$file_with_path")
    fi
  fi
  ((++index))
done

for path_uniq in "${paths[@]}"; do
  pushd "$path_uniq" >/dev/null
  terraform fmt
  popd >/dev/null
done

# terraform.tfvars are excluded by `terraform fmt` so we need to manually specify the files
for tfvars_file in "${tfvars_files[@]}"; do
  terraform fmt "$tfvars_file"
done
