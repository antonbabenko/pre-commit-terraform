#!/usr/bin/env bash
# End-to-end tests for the hooks in this repo (see GH issue #823).
#
# Each test case lives in `tests/e2e/cases/<hook_id>/<case_name>/` and contains:
#   .pre-commit-config.yaml  - `repo: local` config; `__PCT_REPO__` is replaced
#                              with the repo root so `entry` resolves.
#   input/                   - working tree the hook runs against.
#   expected/                - the working tree as it should look AFTER the hook
#                              ran (input files + any generated/modified files).
#   expected_returncode      - optional; expected `pre-commit run` exit code (default 0).
#   requires                 - optional; one CLI tool per line. Case is SKIPPED
#                              if any is missing from PATH.
#
# A case passes when the `pre-commit run` exit code matches `expected_returncode`
# AND the resulting working tree is byte-identical to `expected/`.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
readonly CASES_DIR="$SCRIPT_DIR/cases"

REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
readonly REPO_ROOT

# Colors (disabled when not a TTY).
if [[ -t 1 ]]; then
  C_RED=$'\033[31m' C_GREEN=$'\033[32m' C_YELLOW=$'\033[33m' C_RESET=$'\033[0m'
else
  C_RED='' C_GREEN='' C_YELLOW='' C_RESET=''
fi
readonly C_RED C_GREEN C_YELLOW C_RESET

declare -i passed=0 failed=0 skipped=0
declare -a summary=()

# Run a single case dir. Returns non-zero on failure.
function run_case {
  local case_dir="$1"
  local case_name hook_id test_id
  case_name="$(basename "$case_dir")"
  hook_id="$(basename "$(dirname "$case_dir")")"
  test_id="${hook_id}/${case_name}"

  # Skip when a required tool is absent.
  if [[ -f "$case_dir/requires" ]]; then
    local tool
    while read -r tool || [[ -n $tool ]]; do
      [[ -z $tool || $tool == \#* ]] && continue
      if ! command -v "$tool" > /dev/null 2>&1; then
        summary+=("${C_YELLOW}SKIP${C_RESET} ${test_id} (missing: ${tool})")
        skipped+=1
        return 0
      fi
    done < "$case_dir/requires"
  fi

  local work config log
  work="$(mktemp -d)"
  config="$(mktemp)"
  log="$(mktemp)"
  # shellcheck disable=SC2064 # expand paths now, on purpose
  trap "rm -rf '$work' '$config' '$log' '$log.diff'" RETURN

  # Materialize the input working tree as a git repo (hooks and pre-commit
  # both expect one; the wrapper hook calls `git rev-parse --show-toplevel`).
  cp -R "$case_dir/input/." "$work/"
  git -C "$work" init -q
  git -C "$work" add -A
  git -C "$work" \
    -c user.email=e2e@example.invalid -c user.name='e2e' \
    commit -qm 'e2e fixture' --no-verify

  # Render the per-case config, pointing `entry` at this checkout.
  sed "s|__PCT_REPO__|${REPO_ROOT}|g" \
    "$case_dir/.pre-commit-config.yaml" > "$config"

  local actual_rc=0
  (
    cd "$work"
    pre-commit run --config "$config" --all-files
  ) > "$log" 2>&1 || actual_rc=$?

  local expected_rc=0
  [[ -f "$case_dir/expected_returncode" ]] &&
    expected_rc="$(cat "$case_dir/expected_returncode")"

  # Drop the throwaway git dir so the tree compare only sees fixture output.
  # `git diff --no-index` is used instead of `diff -r` because the project
  # image ships BusyBox `diff`, which lacks `--exclude` and `-u`.
  rm -rf "$work/.git"

  local ok=true reason=''
  if [[ $actual_rc -ne $expected_rc ]]; then
    ok=false
    reason="exit code ${actual_rc}, expected ${expected_rc}"
  elif ! git --no-pager diff --no-index --exit-code \
    "$case_dir/expected" "$work" > "$log.diff" 2>&1; then
    ok=false
    reason='output differs from expected/'
  fi

  if [[ $ok == true ]]; then
    summary+=("${C_GREEN}PASS${C_RESET} ${test_id}")
    passed+=1
    return 0
  fi

  summary+=("${C_RED}FAIL${C_RESET} ${test_id} (${reason})")
  failed+=1
  echo "${C_RED}--- FAIL: ${test_id} (${reason}) ---${C_RESET}"
  echo "pre-commit output:"
  sed 's/^/  /' "$log"
  if [[ -s "$log.diff" ]]; then
    echo "diff (expected vs actual):"
    sed 's/^/  /' "$log.diff"
  fi
  rm -f "$log.diff"
  return 1
}

function main {
  if [[ ! -d $CASES_DIR ]]; then
    echo "No cases dir at ${CASES_DIR}" >&2
    exit 1
  fi

  local case_dir
  while IFS= read -r -d '' case_dir; do
    run_case "$case_dir" || true
  done < <(find "$CASES_DIR" -mindepth 2 -maxdepth 2 -type d -print0 | sort -z)

  echo
  echo '==== e2e summary ===='
  local line
  for line in "${summary[@]}"; do
    echo "  $line"
  done
  echo "  ${passed} passed, ${failed} failed, ${skipped} skipped"

  [[ $failed -eq 0 ]]
}

main "$@"
