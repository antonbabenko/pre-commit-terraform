## 1. Test file scaffolding

- [x] 1.1 Create `tests/pytest/tool_version_test.py`, matching this repo's `<subject>_test.py` naming convention, module docstring, type hints, single-quoted strings
- [x] 1.2 Add shared helpers: temp git repo fixture, temp `PCT_TOOL_CACHE_DIR` fixture, a helper that writes a fake executable stub at a given cache path
- [x] 1.3 Add `@pytest.mark.skipif(sys.platform == 'win32', reason=...)` applied to every hook-subprocess test (or at module level if the whole module is hook-subprocess-only)

## 2. Network-free scenarios (cache pre-population)

- [x] 2.1 Cache-hit: pre-populate cache for `terraform_tflint.sh` with a fake `tflint` stub, invoke with `--hook-config=--tool-version=<version>`, assert stub was used and no download occurred
- [x] 2.2 `--tool-version-mode=strict` (default): pin a version different from a fake local stub on `$PATH`, assert the pinned/cached version wins
- [x] 2.3 `--tool-version-mode=prefer-local`: same setup, assert the local stub is used instead and no cache/download path is attempted
- [x] 2.4 `--tf-path=terraform` + `--tool-version`: pre-populate cache under `terraform`, invoke `terraform_fmt.sh`, assert resolved to the terraform-path cache entry
- [x] 2.5 `--tf-path=opentofu` and `--tf-path=tofu` (alias) + `--tool-version`: pre-populate cache under `opentofu`, assert both values resolve to it
- [x] 2.6 `--tf-path=<invalid-value>` + `--tool-version`: assert non-zero exit and an error message
- [x] 2.7 checkov no-op: invoke `terraform_checkov.sh` with `--hook-config=--tool-version=<version>` set, assert no resolution attempt/error (documented no-op)
- [x] 2.8 Actionable not-found error: invoke a hook whose tool isn't on `$PATH` and no `--tool-version` set, assert non-zero exit and an error naming the tool

## 3. Real-network scenario

- [x] 3.1 Cache-miss/download: invoke `terraform_tflint.sh` with `--hook-config=--tool-version=<small pinned version>` against an empty cache, assert the resulting binary exists, is executable, and reports the pinned version when run with `--version`

## 4. Verification

- [x] 4.1 Run the new test file locally: `pytest tests/pytest/tool_version_test.py -v`
- [x] 4.2 Run the full existing suite (`tox -e pytest` or equivalent) to confirm no regressions in the two pre-existing test modules
- [x] 4.3 Confirm no `.github/workflows/*.yml`, `tox.ini`, or `pyproject.toml` changes were needed (per design Decision 6) - new file picked up by existing discovery
- [x] 4.4 Confirm hook-subprocess tests are correctly skipped when simulated on `win32` (e.g. via `monkeypatch.setattr(sys, 'platform', 'win32')` on the skip condition itself, or by inspecting collected test IDs with `-k` / `--collect-only` under a forced platform check)
