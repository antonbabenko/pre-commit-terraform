#!/usr/bin/env bash

for file in "$@"; do
  terraform fmt `dirname $file`
done
