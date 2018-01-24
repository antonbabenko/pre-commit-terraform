#!/usr/bin/env bash

for file in "$@"; do
  terraform validate -check-variables=true "$file"
done
