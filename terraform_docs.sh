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

readonly tmp_file="tmp_$(date | md5).txt"

for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
  path_uniq="${path_uniq//__REPLACED__SPACE__/ }"

  pushd "$path_uniq" > /dev/null

  terraform-docs md ./ > "$tmp_file"

  sed -i -n -e '/BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK/{p;:a;N;/END OF PRE-COMMIT-TERRAFORM DOCS HOOK/!ba;s/.*\n/r $tmp_file\n/};p' README.md

#  sed -i -e "/I_WANT_TO_BE_REPLACED/r $tmp_file" -e "//d" README.md

#  rm -f "$tmp_file"

  popd > /dev/null
done
