#!/usr/bin/env bash
set -e

declare -a paths
declare -a tfvars_files

index=0

for file_with_path in "$@"; do
  file_with_path="${file_with_path// /__REPLACED__SPACE__}"

  paths[index]=$(dirname "$file_with_path")

  if [[ "$file_with_path" == *".tfvars" ]]; then
    tfvars_files+=("$file_with_path")
  fi

  let "index+=1"
done

for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
  path_uniq="${path_uniq//__REPLACED__SPACE__/ }"

  pushd "$path_uniq" > /dev/null
  DOCS=$(terraform-docs md ./)
  perl -s0pe 's/(<!-- BEGINNING OF TERRAFORM-DOCS HOOK -->).*(<!-- END OF TERRAFORM-DOCS HOOK -->)/\1\n$replacement\n\2/s' -- -replacement="$DOCS" README.md
  sed -i '$d' README.md
  popd > /dev/null
done
