#!/usr/bin/env bash
set -eo pipefail

for d in $(ls -d */); do
  terraform-docs md $d >$d/README.md
  if [ $? -eq 0 ]; then
    git add "./$d/README.md"
  fi
done
