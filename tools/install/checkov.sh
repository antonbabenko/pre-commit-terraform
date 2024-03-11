#!/usr/bin/env bash
set -eo pipefail
# shellcheck disable=SC1091 # Created by Dockerfile above script call
source /.env

if [[ $CHECKOV_VERSION != false ]]; then
  apk add --no-cache \
    gcc=~12 \
    libffi-dev=~3 \
    musl-dev=~1

  # cargo, gcc, git, musl-dev, rust and CARGO envvar required for compilation of rustworkx@0.13.2, no longer required once checkov version depends on rustworkx >0.14.0
  # https://github.com/bridgecrewio/checkov/pull/6045
  # gcc libffi-dev musl-dev required for compilation of cffi, until it contains musl aarch64
  export CARGO_NET_GIT_FETCH_WITH_CLI=true
  apk add --no-cache \
    cargo=~1 \
    git=~2 \
    libgcc=~12 \
    rust=~1

  if [[ $CHECKOV_VERSION == latest ]]; then
    pip3 install --no-cache-dir checkov
  else
    pip3 install --no-cache-dir "checkov==${CHECKOV_VERSION}"
  fi

  apk del gcc libffi-dev musl-dev
  apk del cargo git rust
fi
