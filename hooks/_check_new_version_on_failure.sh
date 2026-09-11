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
  # Hold the tag list, one "<commit-sha><TAB>refs/tags/<name>" line per
  # tag - normalized from the raw `git ls-remote --tags` output (see
  # below), not that raw output verbatim
  local -r tags_cache_file="$cache_root/.last_update_check_tags"
  # HEAD of *this* hook's own checkout - the pinned `rev` - not of the
  # user's project repo, which is this function's actual CWD.
  local -r hooks_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  local current_sha
  current_sha=$(git -C "$hooks_dir" rev-parse HEAD 2> /dev/null) || current_sha=""
  #
  # Try to get tags from valid cache when possible
  #
  local known_tags=""
  local cache_is_fresh=false
  if [[ -f $time_cache_file ]]; then
    local cached_time
    cached_time=$(< "$time_cache_file")
    local -r age_seconds=$(($(date +%s) - cached_time))
    if [[ $age_seconds -lt 604800 ]]; then
      cache_is_fresh=true
      [[ -f $tags_cache_file ]] && known_tags=$(< "$tags_cache_file")
    fi
  fi

  if [[ $cache_is_fresh == true && -z $known_tags ]]; then
    # Rate-limited, and no tag data has ever been cached (e.g. every
    # attempt this week has failed) - nothing to compare against, so
    # stay silent rather than nagging off no data. Only the timestamp,
    # not the tag list, is what the 7-day window actually gates - a
    # second failing run minutes after the first must not re-query
    # just because no tags happen to exist yet.
    return
  fi
  #
  # No/stale cache, need to go to network
  #
  if [[ $cache_is_fresh == false ]]; then
    # `timeout` isn't guaranteed on every platform (e.g. stock macOS
    # without GNU coreutils), so the 3s bound is enforced by hand: run
    # `git ls-remote` in the background, race it against a `sleep 3`
    # watchdog, and kill whichever loses. Output goes to a temp file
    # since a backgrounded command can't be captured with `$(...)`.
    local fresh_output
    local tmp_output
    tmp_output=$(mktemp)
    git ls-remote --tags --sort=version:refname https://github.com/antonbabenko/pre-commit-terraform > "$tmp_output" 2>&1 &
    local git_pid=$!
    (
      sleep 3
      kill -9 "$git_pid" 2> /dev/null || true
      # Redirected above: if `sleep`'s own child process outlives the
      # `kill` sent to this subshell below (SIGTERM to a foreground
      # `sleep` orphans it rather than propagating), an inherited copy
      # of the caller's stdout/stderr pipe would otherwise stay open -
      # and callers reading that pipe until EOF (e.g. Python's
      # `subprocess.communicate`) would block for the orphan's full
      # remaining sleep, not just until `git` actually finishes.
    ) > /dev/null 2>&1 &
    local watchdog_pid=$!

    local exit_code=0
    wait "$git_pid" 2> /dev/null || exit_code=$?
    kill "$watchdog_pid" 2> /dev/null || true
    wait "$watchdog_pid" 2> /dev/null || true

    fresh_output=$(< "$tmp_output")
    rm -f "$tmp_output"

    if [[ $exit_code -eq 0 ]]; then
      # Without `--refs`, `git ls-remote` yields *two* lines for an
      # annotated tag: its own ref (sha = the tag *object*, never a
      # commit) and a peeled "<ref>^{}" line (sha = the commit it
      # actually points at). Only the peeled sha can ever match
      # `current_sha`, so collapse each pair to one line, preferring
      # the peeled sha whenever a tag has one; lightweight tags (single
      # line, already a commit sha) pass through unchanged.
      known_tags=$(awk -v OFS='\t' '
        {
          if (prev_ref != "" && $2 == prev_ref "^{}") {
            print $1, prev_ref
            prev_ref = ""
            next
          }
          if (prev_ref != "") print prev_sha, prev_ref
          prev_sha = $1
          prev_ref = $2
        }
        END {
          if (prev_ref != "") print prev_sha, prev_ref
        }
      ' <<< "$fresh_output")
      mkdir -p "$cache_root"
      date +%s > "$time_cache_file"
      echo "$known_tags" > "$tags_cache_file"
    else
      # 137 = 128 + SIGKILL(9) - the watchdog fired.
      if [[ $exit_code -eq 137 ]]; then
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

# Check for update only on hooks failure. `errexit` is disabled around
# the call and the original pending status is captured/re-exited
# explicitly - otherwise any unguarded failure inside the checker
# itself (e.g. an unwritable cache dir) would, under `set -e`, replace
# the hook's real exit code with the checker's own failure instead of
# just being a best-effort, non-fatal notice.
# shellcheck disable=SC2154 # False positive: assigned inside the trap string itself
trap '
  _pct_update_check_exit_code=$?
  if [[ $_pct_update_check_exit_code -ne 0 ]]; then
    set +e
    _check_new_version_on_failure
    set -e
  fi
  exit $_pct_update_check_exit_code
' EXIT
