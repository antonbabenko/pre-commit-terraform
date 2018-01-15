#!/usr/bin/env bash

for file in "$@"; do
  echo "=======000"
  echo "$file"
  echo `dirname $file`
  echo "=======111"

  terraform fmt "$file"
done
