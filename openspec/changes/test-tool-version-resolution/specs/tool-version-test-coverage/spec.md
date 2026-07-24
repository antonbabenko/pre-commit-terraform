## ADDED Requirements

### Requirement: Automated regression coverage for tool-version resolution
The test suite SHALL provide automated, CI-executed coverage proving that the `hook-config-tool-version` capability (cache hit/miss, `--tool-version-mode`, the `--tf-path` selector, scope exclusions, and error reporting) behaves as specified, by invoking real hook scripts as subprocesses rather than calling bash-internal functions directly.

#### Scenario: Cache-hit resolution verified without network access
- **WHEN** a hook script is invoked with `--hook-config=--tool-version=<version>` and a matching binary already exists at the expected cache path
- **THEN** the test suite verifies the hook used that cached binary and made no network request, by pre-populating the cache with a recognizable fake executable before invoking the hook

#### Scenario: Cache-miss resolution verified with a real download
- **WHEN** a hook script is invoked with `--hook-config=--tool-version=<version>` and no matching binary exists in the cache
- **THEN** at least one test performs a genuine end-to-end download of a small real tool and asserts the resulting cached binary is executable and reports the requested version

#### Scenario: `--tool-version-mode` precedence verified
- **WHEN** a hook script is invoked with `--hook-config=--tool-version-mode=strict` or `--hook-config=--tool-version-mode=prefer-local`
- **THEN** the test suite verifies `strict` uses the pinned/cached version even when a different version is locally available, and `prefer-local` uses the local version instead when present

#### Scenario: `--tf-path` selector verified
- **WHEN** `terraform_fmt.sh` (or another Terraform-consuming hook) is invoked with `--hook-config=--tf-path=terraform`, `--hook-config=--tf-path=opentofu`, or `--hook-config=--tf-path=tofu`, combined with `--hook-config=--tool-version=<version>`
- **THEN** the test suite verifies each value resolves to the correspondingly pinned tool, and an unrecognized `--tf-path` value combined with `--tool-version` produces a non-zero exit code

#### Scenario: Actionable not-found error verified
- **WHEN** a hook script is invoked with no `--tool-version` set and its wrapped tool is not present on `$PATH`
- **THEN** the test suite verifies the hook exits non-zero with an error message naming the missing tool

### Requirement: Tests remain valid across a future hook-implementation-language change
The test suite SHALL assert only on each hook's external CLI contract (process exit code, filesystem state, stdout/stderr content) and SHALL NOT depend on any bash-internal function name or implementation detail, so the same tests require minimal changes if a hook is later reimplemented in a different language.

#### Scenario: Test invokes a hook by file path, not by sourcing bash internals
- **WHEN** a test in this suite exercises hook behavior
- **THEN** it does so via `subprocess`, invoking the hook's script file directly, and never sources `hooks/_common.sh` or calls a `common::*` bash function directly

### Requirement: Hook-subprocess tests are skipped on unsupported platforms
The test suite SHALL skip tests that invoke hook scripts as subprocesses when running on Windows, consistent with this repository's documented position that Windows hook execution is not fully supported.

#### Scenario: Windows CI run skips hook-subprocess tests
- **WHEN** the test suite runs on a Windows CI runner
- **THEN** every test that invokes a `hooks/*.sh` script as a subprocess is skipped, and the run still completes without failing on that platform

### Requirement: No new CI configuration required
The test suite SHALL be discoverable and runnable by this repository's existing test infrastructure without any changes to `.github/workflows/*.yml`, `tox.ini`, or `pyproject.toml`.

#### Scenario: New test file is auto-discovered
- **WHEN** a new `tests/pytest/*_test.py` file is added containing this suite
- **THEN** the existing `tests` CI job's `tox`/`pytest` invocation discovers and runs it without any workflow or configuration changes
