#!/usr/bin/env bash
set -e

declare -a paths
index=0
error=0

for file_with_path in "$@"; do
  file_with_path="${file_with_path// /__REPLACED__SPACE__}"

  paths[index]=$(dirname "$file_with_path")
  (("index+=1"))
done

for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
  path_uniq="${path_uniq//__REPLACED__SPACE__/ }"

  if [[ -n "$(find $path_uniq -maxdepth 1 -name '*.tf' -print -quit)" ]]; then

    starting_path=$(realpath "$path_uniq")
    terraform_path="$path_uniq"

    # Find the relevant .terraform directory (indicating a 'terraform init'),
    # but fall through to the current directory.
    while [[ "$terraform_path" != "." ]]; do
      if [[ -d "$terraform_path/.terraform" ]]; then
        break
      else
        terraform_path=$(dirname "$terraform_path")
      fi
    done

    validate_path="${path_uniq#"$terraform_path"}"

    # Change to the directory that has been initialized, run validation, then
    # change back to the starting directory.
    cd "$(realpath "$terraform_path")"
    if ! terraform validate $validate_path; then
      error=1
      echo
      echo "Failed path: $path_uniq"
      echo "================================"
    fi
    cd "$starting_path"
  fi
done

if [[ "${error}" -ne 0 ]]; then
  exit 1
fi
