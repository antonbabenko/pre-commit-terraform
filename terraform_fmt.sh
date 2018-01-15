#!/usr/bin/env bash

for file in "$@"; do
  terraform fmt "$file"
done
