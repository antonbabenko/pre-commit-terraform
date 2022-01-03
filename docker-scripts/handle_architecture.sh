#!/usr/bin/env ash
# shellcheck shell=dash

set -exuo pipefail

case $(uname -m) in
  armv7l)
    echo "export ARCH=arm64" >> /.env
    ;;
  *)
    echo "export ARCH=amd64" >> /.env
    ;;
esac
