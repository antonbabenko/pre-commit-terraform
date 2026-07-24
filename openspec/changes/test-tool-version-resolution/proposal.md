## Why

The `--hook-config=--tool-version=X.Y.Z` resolution feature (`hook-config-tool-version`, now archived, spec at `openspec/specs/hook-config-tool-version/spec.md`) is currently verified only by ad-hoc scripts that lived outside the repo during development and don't run anywhere now - there is no automated, checked-in, CI-executed regression coverage for any of its 14 requirements. A future refactor (e.g. the hooks-in-Python rewrite already scaffolded under `src/pre_commit_terraform/`) could silently break `--tool-version` resolution with nothing to catch it.

## What Changes

- New pytest test module under `tests/pytest/` covering the 14 requirements / 25 scenarios of the `hook-config-tool-version` spec, black-box style: each test invokes a real hook script (`hooks/*.sh`) as a subprocess and asserts on exit code, cache-directory filesystem state, and stdout/stderr - not on bash-internal function names. This is what lets the same tests keep working, largely unchanged, against a future `hooks/*.py` rewrite (only the invoked file's extension/interpreter would need to change).
- Most scenarios (cache-hit, `--tool-version-mode`, `--tf-path` selector, checkov no-op, actionable not-found error) run network-free, by pre-populating the cache directory with a fake executable stub before invoking the hook. One scenario (cache-miss → real download) uses a small real tool (`hcledit`) for genuine end-to-end coverage of the download path.
- Hook-subprocess tests are skipped on Windows (`sys.platform == 'win32'`), matching this repo's own documented position that Windows hook execution isn't fully supported/reproducible (`.github/CONTRIBUTING.md` / README's Windows section).
- No `.github/workflows/*.yml` changes: confirmed the existing `tests` job already auto-discovers every `tests/pytest/*_test.py` file via `tox`/`pytest` across its current Python 3.10-3.14 × {ubuntu-24.04, macos-15, macos-15-intel, windows-2025} matrix.

## Capabilities

### New Capabilities
- `tool-version-test-coverage`: automated, CI-executed regression tests proving the `--hook-config=--tool-version=X.Y.Z` resolution feature (cache hit/miss, `--tool-version-mode`, the `--tf-path` selector, scope exclusions, and error reporting) behaves correctly, verified against the hook CLI's external interface rather than its bash implementation.

### Modified Capabilities
(none - this change adds verification for the existing `hook-config-tool-version` capability; it does not alter that capability's own requirements)

## Impact

- New file: `tests/pytest/tool_version_test.py` (exact name pending - matches this repo's `<subject>_test.py` suffix convention, e.g. `terraform_docs_replace_test.py`).
- No changes to `hooks/*.sh`, `hooks/_common.sh`, or `tools/install/*.sh` - this change is test-only.
- No changes to `.github/workflows/*.yml`, `tox.ini`, `pyproject.toml`, or `.coveragerc` - existing pytest discovery and dependency groups (`pytest`, `pytest-mock`, `pytest-cov`) already cover everything needed.
