#!/usr/bin/env bash
set -eo pipefail

#######################################################################
# Check for newer pre-commit-terraform release and notify if outdated.
# The remote query is rate-limited to once per 7 days; within that
# window, an already-known-outdated pin still gets renagged every
# failing run, using cached tag data instead of a fresh query.
# Globals:
#   CI (string) if set, skip entirely
#   PCT_SKIP_UPDATE_CHECK (string) if set, skip entirely
#   PCT_TOOL_CACHE_DIR (string) cache root location
#   XDG_CACHE_HOME (string) fallback cache location
#   HOME (string) fallback cache location
# Arguments:
#   None
# Outputs:
#   Prints a yellow notice if pinned revision is behind latest upstream tag,
#   or if HEAD is untagged while a newer release exists. Prints nothing
#   when already up-to-date or when check was skipped.
#######################################################################
function _check_new_version_on_failure {
  if [[ -n ${CI:-} ]] || [[ -n ${PCT_SKIP_UPDATE_CHECK:-} ]]; then
    return
  fi

  local -r cache_root="${PCT_TOOL_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/pre-commit-terraform}"
  # Holds only the last-checked timestamp
  local -r time_cache_file="$cache_root/.last_update_check_time"
  # Hold the raw `git ls-remote --tags` output, one "<sha><TAB>refs/tags/<name>" line per tag
  local -r tags_cache_file="$cache_root/.last_update_check_tags"
  local -r current_sha=$(git rev-parse HEAD)
  #
  # Try to get tags from valid cache when possible
  #
  local known_tags=""
  if [[ -f $time_cache_file ]]; then
    local cached_time
    cached_time=$(< "$time_cache_file")
    local -r age_seconds=$(($(date +%s) - cached_time))
    if [[ $age_seconds -lt 604800 ]] && [[ -f $tags_cache_file ]]; then
      known_tags=$(< "$tags_cache_file")
    fi
  fi
  #
  # No/stale cache, need to go to network
  #
  if [[ -z $known_tags ]]; then
    local fresh_output

    if fresh_output=$(timeout 3 git ls-remote --tags --refs --sort=version:refname https://github.com/antonbabenko/pre-commit-terraform 2>&1); then
      known_tags=$fresh_output
      mkdir -p "$cache_root"
      date +%s > "$time_cache_file"
      echo "$known_tags" > "$tags_cache_file"
    else
      local exit_code=$?
      if [[ $exit_code -eq 124 ]]; then
        common::colorify "yellow" "Update check timed out."
      else
        common::colorify "yellow" "Update check failed (exit ${exit_code})."
      fi
      common::colorify "yellow" "Will try again in a week." \
        "Set CI=true or PCT_SKIP_UPDATE_CHECK=true to never check for updates."

      # Skip update check for a week
      mkdir -p "$cache_root"
      date +%s > "$time_cache_file"
      return
    fi
  fi
  #
  # Valid cache
  #
  local latest_tag_name
  latest_tag_name=$(echo "$known_tags" | tail -n1 | awk '{print $2}' | sed 's|^refs/tags/||')

  # Find which tag, if any, matches current HEAD
  local current_tag=""
  while IFS=$'\t' read -r sha tag; do
    if [[ $sha == "$current_sha" ]]; then
      current_tag=${tag#refs/tags/}
      break
    fi
  done <<< "$known_tags"

  if [[ $latest_tag_name == "$current_tag" ]]; then
    # Already up-to-date, silent
    return
  elif [[ -n $current_tag ]]; then
    common::colorify "yellow" "pre-commit-terraform ${current_tag} is outdated; latest is ${latest_tag_name}."
  else
    common::colorify "yellow" "pre-commit-terraform pinned to a non-release commit; latest release is ${latest_tag_name}."
  fi
  common::colorify "yellow" 'Run "pre-commit autoupdate --freeze" (or "prek update --freeze") to upgrade.'
}

# Check for update only on hooks failure
trap '[[ $? -ne 0 ]] && _check_new_version_on_failure' EXIT
