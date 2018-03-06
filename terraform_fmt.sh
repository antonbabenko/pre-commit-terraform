#!/usr/bin/env bash
set -e

declare -a paths
declare -a tfvars_files
index=0

echo "$@"

for file_with_path in "$@"; do
  paths[index]=$(dirname "$file_with_path")

  if [[ "$file_with_path" == *".tfvars" ]]; then
    tfvars_files+=("$file_with_path")
  fi

  let "index+=1"
done

echo "${tfvars_files[@]}"

for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
  pushd "$path_uniq" > /dev/null
  terraform fmt
  popd > /dev/null
done

# terraform.tfvars are excluded by `terraform fmt`
for tfvars_file in "${tfvars_files[@]}"; do
  echo "tfvars_file = ${tfvars_file}"
  echo
  terraform fmt "$tfvars_file"
done
