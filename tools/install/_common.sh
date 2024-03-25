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
readonly VERSION="${!env_var_name}"

# Skip tool installation if the version is set to "false"
if [[ $VERSION == false ]]; then
  echo "'$TOOL' skipped"
  exit 0
fi

#######################################################################
# Install the latest or specific version of the tool from GitHub release
# Globals:
#   TOOL - Name of the tool
#   VERSION - Version of the tool
# Arguments:
#   GH_ORG - GitHub organization name where the tool is hosted
#   DISTRIBUTED_AS - How the tool is distributed.
#     Can be: 'tar.gz', 'zip' or 'binary'
#   GH_RELEASE_REGEX_LATEST - Regular expression to match the latest
#     release URL
#   GH_RELEASE_REGEX_SPECIFIC_VERSION - Regular expression to match the
#      specific version release URL
#   UNUSUAL_TOOL_NAME_IN_PKG - If the tool in the tar.gz package is
#     not in the root or named differently than the tool name itself,
#     For example, includes the version number or is in a subdirectory
#######################################################################
function common::install_from_gh_release {
  local -r GH_ORG=$1
  local -r DISTRIBUTED_AS=$2
  local -r GH_RELEASE_REGEX_LATEST=$3
  local -r GH_RELEASE_REGEX_SPECIFIC_VERSION=$4
  local -r UNUSUAL_TOOL_NAME_IN_PKG=$5

  case $DISTRIBUTED_AS in
    tar.gz | zip)
      local -r PKG="${TOOL}.${DISTRIBUTED_AS}"
      ;;
    binary)
      local -r PKG="$TOOL"
      ;;
    *)
      echo "Unknown DISTRIBUTED_AS: '$DISTRIBUTED_AS'. Should be one of: 'tar.gz', 'zip' or 'binary'." >&2
      exit 1
      ;;
  esac

  # Download tool
  local -r RELEASES="https://api.github.com/repos/${GH_ORG}/${TOOL}/releases"

  if [[ $VERSION == latest ]]; then
    curl -L "$(curl -s "${RELEASES}/latest" | grep -o -E -i -m 1 "$GH_RELEASE_REGEX_LATEST")" > "$PKG"
  else
    curl -L "$(curl -s "$RELEASES" | grep -o -E -i -m 1 "$GH_RELEASE_REGEX_SPECIFIC_VERSION")" > "$PKG"
  fi

  # Make tool ready to use
  if [[ $DISTRIBUTED_AS == tar.gz ]]; then
    if [[ -z $UNUSUAL_TOOL_NAME_IN_PKG ]]; then
      tar -xzf "$PKG" "$TOOL"
    else
      tar -xzf "$PKG" "$UNUSUAL_TOOL_NAME_IN_PKG"
      mv "$UNUSUAL_TOOL_NAME_IN_PKG" "$TOOL"
    fi
    rm "$PKG"

  elif [[ $DISTRIBUTED_AS == zip ]]; then
    unzip "$PKG"
    rm "$PKG"
  else
    chmod +x "$PKG"
  fi
}
