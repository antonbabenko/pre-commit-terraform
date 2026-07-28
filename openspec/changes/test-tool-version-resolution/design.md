## Context

The `hook-config-tool-version` capability (archived; spec at `openspec/specs/hook-config-tool-version/spec.md`) is implemented entirely in bash (`hooks/_common.sh`'s `common::resolve_tool_version`/`common::get_tf_binary_path`, wired via a `tool_name` parameter into all 16 `hooks/*.sh` scripts). It was verified during development only via ad-hoc scripts that never entered the repo. `tests/pytest/` currently contains exactly two test modules (`_cli_test.py`, `terraform_docs_replace_test.py`), both testing the pure-Python `src/pre_commit_terraform/` package via direct imports + `mocker`/`monkeypatch` - there is no existing precedent for testing a `hooks/*.sh` script's runtime behavior. CI (`.github/workflows/ci-cd.yml` → `reusable-tox.yml`) already auto-discovers every `tests/pytest/*_test.py` across a Python 3.10-3.14 × {ubuntu-24.04, macos-15, macos-15-intel, windows-2025} matrix, with outbound network access available.

## Goals / Non-Goals

**Goals:**
- Automated, checked-in, CI-executed regression coverage for the `hook-config-tool-version` capability's 14 requirements / 25 scenarios.
- Tests verify the hook's *external* CLI contract (invoke the script, check exit code / filesystem / output) rather than bash-internal function names, so they remain valid with minimal changes if hooks are ever rewritten in another language.
- Minimize real network calls; most scenarios must be provable without hitting GitHub.

**Non-Goals:**
- Testing every one of the 16 wired hook scripts individually - one representative hook per code path (a "mine"-style hook and a Terraform-consuming hook) is enough to prove the shared `hooks/_common.sh` logic; per-hook wiring is already exercised by the repo's existing hook-level tests/CI.
- Testing bash-internal function signatures (`common::resolve_tool_version` by name) as a *primary* strategy - see Decision 1.
- A Python-hook version of these tests - `src/pre_commit_terraform/` doesn't have a tool-version-resolving hook yet; out of scope until that rewrite happens.
- Checksum/signature verification, GitHub API rate-limit handling - already out of scope for the feature itself (see archived design.md).

## Decisions

1. **Black-box, subprocess-invocation is the primary (and only) test strategy - no bash-internals unit-test layer.** A `common::resolve_tool_version`-calling test layer would be faster to write and pin down every edge case precisely, but it hard-depends on that bash function existing under that exact name - it would need to be thrown away, not adapted, the moment hooks move to another language. Since the explicit goal is durability across a future rewrite, tests instead do `subprocess.run(['bash', 'hooks/<hook>.sh', '--hook-config=...', '--', 'file.tf'], cwd=tmp_repo)` and assert on `returncode`, the cache directory's filesystem state, and `stdout`/`stderr` content. This is slower per-test and less granular, but it is the only design that satisfies "keep working against a Python rewrite" - the same test, pointed at a future `hooks/<hook>.py`, proves the two implementations behave identically during a migration window.
   *Alternative considered*: bash-internals unit tests (source `_common.sh`, call the function directly) as the *primary* layer - rejected per the goal above. Could still be added later as a supplementary, explicitly-bash-only file if faster edge-case iteration is ever needed; not part of this change.

2. **Two hooks are used as representatives, not all sixteen**: `terraform_tflint.sh` (a "mine"-style hook - exercises the generic `common::resolve_tool_version` path directly) and `terraform_fmt.sh` (a Terraform-consuming hook - exercises the `"tf"` sentinel dispatch into `common::get_tf_binary_path`, including the `--tf-path` selector). Every one of the 14 requirements is reachable through one or the other of these two call paths; the per-hook wiring itself (does hook X pass the right `tool_name`) is a one-line, low-risk pattern already covered by this session's own manual verification and not worth re-proving 16 times over in CI.

3. **Network avoidance via cache pre-population, not mocking.** Rather than monkeypatching `curl`/`common::install_from_gh_release`, tests that need a "cache hit" scenario write a small fake executable (a `#!/usr/bin/env bash` script that echoes a recognizable sentinel and exits 0) directly at the expected cache path (`<tmp_cache_root>/<tool>/<version>/<tool>`) *before* invoking the hook, then assert the hook used that file (via the sentinel appearing in output, or a marker file the stub writes) and that no network call was attempted (implicitly, by running fast and by the stub being deterministic). This covers cache-hit, `--tool-version-mode`, the `--tf-path` selector, the checkov no-op, and the actionable not-found error - i.e. every scenario except the download itself - without touching the network.
   *Alternative considered*: mock `tools/install/<tool>.sh` entirely with a fake installer script committed to the repo - rejected as it would require adding a permanent test-fixture tool under `tools/install/`, which is more invasive to the production tree than pre-populating a tmp cache dir.

4. **One real-network test for the cache-miss/download path, using `hcledit`.** `hcledit` is already used throughout this repo's own hook wiring (`terraform_wrapper_module_for_each`) and is a small (~3MB), fast-downloading binary. A single test resolves it via `terraform_tflint.sh`... actually via a minimal, tool-agnostic path: since `hcledit` isn't itself one of the 16 wired hook tools, this test instead targets `terraform_docs.sh` with `--hook-config=--tool-version=` pinned to a real small `terraform-docs` release, OR, more simply, calls the same real download path already proven manually during development (pin a small real version of a genuinely-wired tool, e.g. `tflint`, through `terraform_tflint.sh`). Accepting the real network dependency and modest CI time cost (a few seconds) as the price of genuine end-to-end proof for this one path.

5. **Hook-subprocess tests are skipped on Windows** (`@pytest.mark.skipif(sys.platform == 'win32', reason=...)`). This repo's own `README.md`/`.github/CONTRIBUTING.md` state Windows hook execution isn't fully supported/reproducible ("We won't be able to help with issues that can't be reproduced in Linux/Mac"). Running bash-subprocess tests unmodified on `windows-2025` risks flaky, unsupported-platform CI failures for a guarantee this repo doesn't make. Still get full coverage on ubuntu-24.04 + macos-15 (both variants) × Python 3.10-3.14.

6. **No `.github/workflows/*.yml`, `tox.ini`, or `pyproject.toml` changes.** Confirmed via direct exploration that the `tests` job already runs `tox -e pytest` (aliasing default `py`), which invokes plain `pytest` with auto-discovery over the whole `tests/pytest/` tree; a new `*_test.py` file needs zero additional wiring to run in every existing CI matrix cell.

## Risks / Trade-offs

- **[Risk]** The one real-download test is subject to GitHub API flakiness/rate limits in CI, same as any other network-dependent test. → **[Mitigation]** Exactly one such test exists; same tolerance this repo already accepts for its own Docker-build-time downloads. `GITHUB_TOKEN` is picked up automatically by the underlying installer script if `CI` sets it, same as production.
- **[Risk]** Fake-stub cache pre-population tests a *shape* (an executable file at the right path) but not the *real* installer script's own correctness - that's already covered by the archived feature's own development-time verification, not re-litigated here. → **[Mitigation]** Accepted; this change's goal is regression coverage for the *resolution logic*, not re-proving each `tools/install/<tool>.sh` script.
- **[Trade-off]** Testing only 2 of 16 wired hooks means a hook-specific wiring mistake (e.g. hook N passes the wrong `tool_name` string) wouldn't be caught by this suite. → **[Mitigation]** Accepted per Decision 2 - the wiring pattern is mechanical and low-risk; full per-hook coverage can be added incrementally later without changing this design.

## Open Questions

None outstanding.
