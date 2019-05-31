#!/usr/bin/env bash
set -e

declare -a paths
index=0

TERRAFORM_CMD="${TERRAFORM_CMD:-terraform}"

for file_with_path in "$@"; do
  file_with_path="${file_with_path// /__REPLACED__SPACE__}"

  paths[index]=$(dirname "$file_with_path")
  (( "index+=1" ))
done

for path_uniq in $(echo "${paths[*]}" | tr ' ' '\n' | sort -u); do
  path_uniq="${path_uniq//__REPLACED__SPACE__/ }"

  pushd "$path_uniq" > /dev/null
  if [[ -n "$(find . -maxdepth 1 -name '*.tf' -print -quit)" ]] ; then
    if ! ${TERRAFORM_CMD} validate -check-variables=false ; then
      echo
      echo "Failed path: $path_uniq"
      echo "================================"
    fi
  fi
  popd > /dev/null
done
