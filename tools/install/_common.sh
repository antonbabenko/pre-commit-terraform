#!/usr/bin/env bash

set -eo pipefail

# Tool name, based on filename.
# Tool filename MUST BE same as in package manager/binary name
TOOL=${0##*/}
readonly TOOL=${TOOL%%.*}

# Get "TOOL_VERSION"
# /.env is created in the Dockerfile before this script runs there; when
# this script is invoked directly (e.g. at hook run-time, outside a Docker
# build), it won't exist and the version env var is expected to already be
# exported by the caller instead.
# shellcheck disable=SC1091
[[ -f /.env ]] && source /.env
env_var_name="${TOOL//-/_}"
# `${var^^}` is bash 4+ only; macOS ships bash 3.2 by default.
env_var_name="$(tr '[:lower:]' '[:upper:]' <<< "${env_var_name}_VERSION")"
# shellcheck disable=SC2034 # Used in other scripts
readonly VERSION="${!env_var_name}"

# Skip tool installation if the version is set to "false"
if [[ $VERSION == false ]]; then
  echo "'$TOOL' skipped"
  exit 0
fi

#######################################################################
# Fetch a GitHub API URL and print its body to stdout.
# Fails fast (exit 1) on transport errors, rate limiting (HTTP 429, or
# HTTP 403 whose body confirms rate limiting) and any non-200 status,
# so callers never mistake an API error payload for release data
# (issue #1023).
# Globals:
#   CURL_CMD - curl command array with auth options; this function is
#     only meant to be called from common::install_from_gh_release,
#     which defines it (bash dynamic scoping).
#   TOOL - Name of the tool (used in error messages)
# Arguments:
#   url - GitHub API URL to GET
# Outputs:
#   Response body on stdout (only when HTTP 200)
# Errors:
#   Diagnostic on stderr; exits 1 on failure
#######################################################################
function common::gh_api_get {
  local -r url=$1
  local response http_code body

  if ! response=$("${CURL_CMD[@]}" -sS -L -w $'\n%{http_code}' "$url"); then
    echo "ERROR: failed to contact GitHub API at '$url'." >&2
    exit 1
  fi

  http_code=${response##*$'\n'}
  body=${response%$'\n'*}

  if [[ $http_code -eq 429 ||
    ($http_code -eq 403 && $(tr '[:upper:]' '[:lower:]' <<< "$body") =~ "rate limit") ]]; then
    echo "ERROR: GitHub API rate limit exceeded while querying '$TOOL' releases (HTTP $http_code)." >&2
    echo 'Pass your GitHub access token by means of exporting "GITHUB_TOKEN" environment variable to send authenticated calls or retry later. See https://docs.github.com/rest/overview/resources-in-the-rest-api#rate-limiting' >&2
    exit 1
  fi

  if [[ $http_code -ne 200 ]]; then
    if [[ $http_code -eq 403 ]]; then
      echo "ERROR: GitHub API request to '$url' failed with HTTP $http_code (Forbidden)." >&2
    else
      echo "ERROR: GitHub API request to '$url' failed with HTTP $http_code." >&2
    fi
    exit 1
  fi

  printf '%s' "$body"
}

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
  local CURL_OPTS=()

  [[ $GITHUB_TOKEN ]] && CURL_OPTS+=('-H' "Authorization: Bearer $GITHUB_TOKEN")

  local -r CURL_CMD=("curl" "${CURL_OPTS[@]}")

  local asset_url="" latest_releases page_releases

  if [[ $VERSION == latest ]]; then
    latest_releases=$(common::gh_api_get "${RELEASES}/latest")
    asset_url=$(grep -o -E -i -m 1 "$GH_RELEASE_REGEX_LATEST" <<< "$latest_releases") || true

    if [[ ! $asset_url ]]; then
      echo "ERROR: Failed to find '$TOOL' latest release asset matching the '$GH_RELEASE_REGEX_LATEST' regex." >&2
      exit 1
    fi
  else
    # Unpaginated $RELEASES only has the 30 newest releases; page
    # through (100/page) until matched or an empty page ends it.
    local page=1
    local -r max_pages=20 # 2000 releases; generous for any wrapped tool
    while [[ -z $asset_url && $page -le $max_pages ]]; do
      page_releases=$(common::gh_api_get "${RELEASES}?per_page=100&page=${page}")
      # GitHub may pretty-print an empty array as "[\n\n]", not "[]" - match
      # an empty JSON array allowing whitespace (anchored regex; ${var//...}
      # pattern substitution is pathologically slow on multi-MB API bodies).
      [[ $page_releases =~ ^[[:space:]]*\[[[:space:]]*\][[:space:]]*$ ]] && break
      asset_url=$(grep -o -E -i -m 1 "$GH_RELEASE_REGEX_SPECIFIC_VERSION" <<< "$page_releases") || true
      ((page++))
    done

    if [[ ! $asset_url ]]; then
      echo "ERROR: could not find a '$TOOL' release asset matching version '$VERSION' (looked through up to $((page - 1)) page(s) of releases)." >&2
      exit 1
    fi
  fi

  if ! "${CURL_CMD[@]}" -sS -f -L "$asset_url" > "$PKG"; then
    echo "ERROR: Failed to download '$TOOL' release asset from '$asset_url'." >&2
    exit 1
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
