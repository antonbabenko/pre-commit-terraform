# End-to-end hook tests

Behavioral tests that run the hooks the same way a user would — through
`pre-commit` against real fixture files — and compare the result against a
committed "golden" output. See [issue #823][issue-823].

## Layout

```text
tests/e2e/
  run_e2e_tests.sh                 # the runner
  cases/<hook_id>/<case_name>/
    .pre-commit-config.yaml        # repo:local config; __PCT_REPO__ -> repo root
    input/                         # working tree the hook runs against
    expected/                      # working tree as it should look AFTER the hook
    expected_returncode            # optional, default 0 (fixing hooks exit 1)
    requires                       # optional, one CLI tool per line; SKIP if missing
```

A case passes when the `pre-commit run` exit code matches `expected_returncode`
**and** the resulting working tree is byte-identical to `expected/`.

Note: hooks that modify tracked files in place (e.g. `terraform_fmt`) make
`pre-commit` exit `1` ("files were modified by this hook"), so those cases set
`expected_returncode` to `1`. Hooks that only generate new files (e.g.
`terraform_wrapper_module_for_each`) leave tracked files untouched and exit `0`.

## Prerequisites

The runner itself needs `pre-commit` and `git`. Each case additionally needs
the tools its hook calls; a case is **skipped** (not failed) when a tool listed
in its `requires` file is missing from `PATH`.

Current cases need:

| Tool | Used by |
| --- | --- |
| `pre-commit`, `git` | the runner (always) |
| `terraform` | `terraform_fmt` |
| `hcledit` | `terraform_wrapper_module_for_each` |

Install locally:

```bash
# macOS (Homebrew)
brew install pre-commit terraform minamijoyo/hcledit/hcledit

# Linux: pre-commit via pip, terraform via HashiCorp's repo, and hcledit:
curl -L "$(curl -s https://api.github.com/repos/minamijoyo/hcledit/releases/latest \
  | grep -o -E -m 1 "https://.+?_linux_amd64.tar.gz")" > hcledit.tar.gz \
  && tar -xzf hcledit.tar.gz hcledit && rm hcledit.tar.gz && sudo mv hcledit /usr/bin/
```

See the repo [README "How to install"](../../README.md#how-to-install) for the
full tool list and other install methods.

Or skip local installs entirely and use the project image, which bundles every
tool (this is what CI does) — see [Running](#running) below.

## Running

Natively:

```bash
bash tests/e2e/run_e2e_tests.sh
```

Inside the project image (matches CI — bundles every tool, no local installs):

```bash
docker build -t pct:e2e --build-arg INSTALL_ALL=true .
docker run --rm -v "$PWD:/lint" -w /lint --entrypoint bash pct:e2e \
  tests/e2e/run_e2e_tests.sh
```

## Adding a case

1. Create `cases/<hook_id>/<case_name>/`.
2. Add `input/` (the fixture) and a `.pre-commit-config.yaml` wiring the hook as
   a `repo: local` hook with `entry: __PCT_REPO__/hooks/<hook>.sh`.
3. Generate `expected/`: run the hook once against a copy of `input/` and commit
   the resulting tree. Set `expected_returncode` if the hook modifies files.
4. Add a `requires` file listing any non-trivial CLI tools the hook needs.

The runner auto-discovers any `cases/<hook_id>/<case_name>/` dir — no runner
changes are needed to cover a new hook.

[issue-823]: https://github.com/antonbabenko/pre-commit-terraform/issues/823
