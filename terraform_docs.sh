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

  ((index+=1))
done

readonly tmp_file="tmp_$(date | md5).txt"
readonly text_file="README.md"

for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
  path_uniq="${path_uniq//__REPLACED__SPACE__/ }"

  pushd "$path_uniq" > /dev/null

  if [[ ! -f "$text_file" ]]; then
    popd > /dev/null
    continue
  fi

  terraform-docs md ./ > "$tmp_file"

  # Replace content between markers with the placeholder - http://fahdshariff.blogspot.no/2012/12/sed-mutli-line-replacement-between-two.html
  sed -i -n '/BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK/{p;:a;N;/END OF PRE-COMMIT-TERRAFORM DOCS HOOK/!ba;s/.*\n/I_WANT_TO_BE_REPLACED\n/};p' "$text_file"

  # Replace placeholder with the content of the file - https://stackoverflow.com/a/31057013/550451
  sed -i -e "/I_WANT_TO_BE_REPLACED/r $tmp_file" -e "//d" "$text_file"

  rm -f "$tmp_file"

  popd > /dev/null
done
