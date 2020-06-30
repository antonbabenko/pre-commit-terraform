#!/usr/bin/env bash
set -e

for file_with_path in "$@"; do
  file_with_path="${file_with_path// /__REPLACED__SPACE__}"
  pushd $(dirname "$file_with_path") > /dev/null
  terraform fmt $(basename "$file_with_path")
  popd > /dev/null
done
