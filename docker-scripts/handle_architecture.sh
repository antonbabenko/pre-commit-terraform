#!/usr/bin/env ash
# shellcheck shell=dash

set -exuo pipefail

case $(uname -m) in
  armv7l)
    {
      echo "export ARCH=arm64"
      echo "export ARCHX=arm64"
    } >> /.env
    ;;
  x86_64)
    {
      echo "export ARCH=amd64"
      echo "export ARCHX=x86_64"
    } >> /.env
    ;;
  *)
    exit 1
    ;;
esac
