#!/usr/bin/env bash

set -eo pipefail

# Tool name, based on filename.
# Tool filename MUST BE same as in package manager/binary name
TOOL=${0##*/}
readonly TOOL=${TOOL%%.*}

# Get "TOOL_VERSION"
# shellcheck disable=SC1091 # Created in Dockerfile before execution of this script
source /.env
env_var_name="${TOOL//-/_}"
env_var_name="${env_var_name^^}_VERSION"
# shellcheck disable=SC2034 # Used in other scripts
VERSION="${!env_var_name}"

# Skip tool installation if the version is set to "false"
if [[ $VERSION == false ]]; then
  echo "'$TOOL' skipped"
  exit 0
fi
