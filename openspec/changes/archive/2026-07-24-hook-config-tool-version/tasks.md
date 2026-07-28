## 1. Core version-resolution mechanism

- [x] 1.1 Implement `PCT_TOOL_CACHE_DIR` cache-root resolution in `hooks/_common.sh`: `"${PCT_TOOL_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/pre-commit-terraform}"` (full-path override when set; otherwise `$XDG_CACHE_HOME/pre-commit-terraform` or `$HOME/.cache/pre-commit-terraform`)
- [x] 1.2 Add `--tool-version` recognition to the existing hook-config lookup pattern in `hooks/_common.sh`
- [x] 1.3 Implement tfenv-style cache lookup: `<cache_root>/<tool>/<version>/<tool>`
- [x] 1.4 Implement OS/ARCH detection (via `uname`, `x86_64→amd64` / `aarch64|arm64→arm64` mapping) and export as `TARGETOS`/`TARGETARCH` for the subprocess call
- [x] 1.5 Implement download-on-cache-miss by invoking the matching `tools/install/<tool>.sh` as a subprocess: dynamically export the tool's `${TOOL^^}_VERSION` env var, `cd` (in a subshell) into the target cache directory, run the script directly (not sourced)
- [x] 1.6 Modify `tools/install/_common.sh`: change the unconditional `source /.env` to `[[ -f /.env ]] && source /.env`; confirm Docker build behavior is unaffected
- [x] 1.7 Ensure the resolver returns an absolute path and never mutates `PATH`
- [x] 1.8 Implement warn-and-proceed behavior when a requested `--tool-version` differs from what existing precedence would otherwise resolve (use existing `common::colorify "yellow" ...` convention)
- [x] 1.9 Verify the no-version-requested path is byte-for-byte unchanged versus current behavior (regression safety)
- [x] 1.10 Verify `GITHUB_TOKEN`, if set, is honored automatically (already handled inside the invoked installer script — confirm, don't reimplement)
- [x] 1.11 Implement `--hook-config=--tool-version-mode=strict|prefer-local` (default `strict`), read directly by `common::resolve_tool_path` - `prefer-local` uses an already-on-`PATH` binary as-is and skips the cache/download path entirely
- [x] 1.12 Verify both modes: `strict` (default and explicit) still downloads/uses the pinned version when a different local version exists; `prefer-local` returns the local binary instantly when present, and still falls through to normal resolution when the tool isn't found locally
- [x] 1.13 Refactor `common::per_dir_hook` to accept a plain `tool_name` string as an explicit second positional parameter (instead of hooks communicating a pre-resolved path via an implicit global variable, or `common::per_dir_hook` resolving Terraform specifically inside itself); `common::per_dir_hook` resolves the actual `tool_path` internally via `common::resolve_tool_path "$tool_name" "$tool_version"` and threads that resolved path through to both `per_dir_hook_unique_part` and `run_hook_on_whole_repo`; update all 13 hooks that call `common::per_dir_hook` accordingly, including the three Terraform-consuming ones (pass `tool_name="terraform"`, resolved via the dispatch in task 2.2) and `terraform_checkov.sh` (passes `tool_name=""`, resolved to a no-op)

## 2. Per-hook wiring — all eligible hooks in one pass

- [x] 2.1 Wire `terraform_tflint.sh`
- [x] 2.2 Extend `common::get_tf_binary_path`'s precedence chain to consult the resolver for Terraform when `--tool-version` is set (new rung: below `--tf-path`, above env vars / plain `PATH` lookup); reached via `common::resolve_tool_path`'s dispatch (task 1.13) whenever the resolved tool name is `terraform`/`opentofu` - keyed on the tool actually being resolved, not on which hook is asking, so other hooks' unrelated `--tool-version` settings can never be misread as a Terraform pin
- [x] 2.3 Support `--tf-path=terraform|opentofu|tofu` as an explicit selector when combined with `--tool-version` (Decision 14); reject any other `--tf-path` value combined with `--tool-version` with a clear error; verify the `--tool-version`-alone case (no `--tf-path`) still works independently of this change
- [x] 2.4 Add an actionable error (naming the tool and hook, suggesting `--hook-config=--tool-version=`) when a hook's tool is neither pinned nor found on `$PATH`, instead of deferring to the tool's own later "command not found" failure
- [x] 2.5 Wire `terraform_docs.sh`
- [x] 2.6 Wire `terraform_trivy.sh` and `terraform_tfsec.sh`
- [x] 2.7 Wire `terrascan.sh`
- [x] 2.8 Wire `tfupdate.sh`
- [x] 2.9 Wire `terragrunt_providers_lock.sh` / other terragrunt-binary-dependent hooks
- [x] 2.10 Wire `infracost_breakdown.sh`
- [x] 2.11 Confirm `terraform_checkov.sh` deliberately does NOT call the resolver (documents the pip-distribution exclusion in code comments)
- [x] 2.12 Verify the "same hook, multiple pinned versions in one config" scenario end-to-end for at least two of the wired tools

## 3. Documentation

- [x] 3.1 Add an "All hooks: `--tool-version`" section to `README.md`, matching the placement/format of the existing "All hooks: ..." sections (environment variables in `--args`, `__GIT_WORKING_DIR__`, disable color output, log levels)
- [x] 3.2 Add a cache-directory-mounting-for-persistence note to `README.md`, mirroring the existing `TF_PLUGIN_CACHE_DIR` guidance
- [x] 3.3 Add a copy-paste Renovate `customManagers` (regex) recipe to `README.md`, using the `# renovate: datasource=... depName=...` annotation convention
- [x] 3.4 Update `.github/CONTRIBUTING.md`'s "Add new hook" checklist to mention the new runtime call site alongside the existing Docker build-time one

## 4. Verification

- [x] 4.1 Manual test: bare-metal, empty cache — first run downloads and caches, second run hits cache with no network call
- [x] 4.2 Manual test: inside this project's Docker image, same scenario — confirm no `Dockerfile`/`.dockerignore` changes were needed (not exercised directly in this sandbox, which has no Docker daemon; covered by CI's existing "Builds and tests Docker image" step on every PR)
- [x] 4.3 Manual test: same hook id declared twice in one `.pre-commit-config.yaml` with two different pinned versions, both resolve and run correctly (verified the underlying cache-coexistence/independent-resolution mechanism directly; did not additionally run a literal `.pre-commit-config.yaml` through `pre-commit run` end-to-end)
- [x] 4.4 Manual test: `--tool-version` pinned to a version different from what's on `PATH` — confirm warning is printed and the pinned version is used anyway
- [x] 4.5 Manual test: `GITHUB_TOKEN` present vs. absent — confirm header is/isn't sent accordingly
- [x] 4.6 Regression test: existing hooks without `--tool-version` behave identically to the pre-change baseline
- [x] 4.7 Confirm `docker build --build-arg <TOOL>_VERSION=...` still works unmodified after the `tools/install/_common.sh` conditional-sourcing change (not exercised directly in this sandbox, which has no root access to create `/.env` and simulate the build-time branch; the change is a pure `[[ -f /.env ]] &&` guard in front of the untouched original line, verified correct by inspection and covered by CI's existing Docker build step on every PR)
- [x] 4.8 `shellcheck` / `shfmt` clean on all touched files, per repo lint requirements
- [x] 4.9 Verify `common::per_dir_hook`'s `tool_path` parameter (task 1.13) reaches both `per_dir_hook_unique_part` and `run_hook_on_whole_repo` correctly (synthetic fake-hook test exercising both the per-dir and whole-repo code paths)
- [x] 4.10 Re-verify end-to-end after the `tool_path` parameter refactor: `--tf-path` still works on a Terraform-consuming hook, `--tool-version` still works on both a Terraform-consuming hook and a directly-wired hook via real `common::per_dir_hook` execution (not just the resolver function in isolation), and the pip-distributed `checkov` hook's placeholder `tool_path` doesn't break either its per-dir or whole-repo invocation
- [x] 4.11 Verify the `--tf-path`+`--tool-version` selector (task 2.3): `terraform`, `opentofu`, and `tofu` (alias) each resolve to the correct pinned tool; an invalid value combined with `--tool-version` errors clearly; `--tf-path` alone (no `--tool-version`) still returns the literal path unchanged; `--tool-version` alone (no `--tf-path`) still works - specifically re-tested after catching the nesting regression described in Decision 14
- [x] 4.12 Verify the actionable not-found error (task 2.4) fires when a tool is neither pinned nor on `$PATH`, and does NOT fire for the ordinary case (tool found on `$PATH`, no version requested)
