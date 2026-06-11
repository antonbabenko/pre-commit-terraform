# AGENTS.md — pre-commit-terraform

## What this repo is

Collection of Git hooks for Terraform/OpenTofu/Terragrunt to be used with the [pre-commit framework](https://pre-commit.com/).
Hooks enforce formatting, validation, documentation, and security scanning across Terraform codebases.

## Directory layout

- `hooks/` — Bash entry points for each hook (`<hook_name>.sh`) + shared `_common.sh`
- `src/pre_commit_terraform/` — Python package: CLI parsing, env expansion, `__GIT_WORKING_DIR__` substitution, `terraform_docs_replace` logic
- `tests/pytest/` — Python unit tests (`pytest`); `tests/Dockerfile` and `tests/hooks_performance_test.sh` for integration/perf testing
- `tools/entrypoint.sh` — Docker container entrypoint (user/group setup)
- `tools/install/` — per-tool install scripts used during Docker image build (one `.sh` per tool)
- `dependencies/lock-files/` — pinned Python dependency constraints for reproducible Docker builds
- `.pre-commit-hooks.yaml` — hook definitions consumed by the pre-commit framework
- `pyproject.toml` / `hatch.toml` — Python project config and build system
- `tox.ini` — test environment matrix

## Hook implementation pattern

Two distinct hook types exist:

**Shell-based hooks** (majority) — `hooks/<hook_name>.sh`:
- Sources `_common.sh` for shared logic: cmdline parsing (`--args`, `--hook-config`, `--env-vars`), env var expansion, `__GIT_WORKING_DIR__` substitution, parallelism, `terraform init`
- Defines `per_dir_hook_unique_part()` — the hook-specific per-directory logic
- `common::per_dir_hook` orchestrates parallelism and calls it for each changed dir

**Python-based hooks** — invoked as `python -m pre_commit_terraform <subcommand>`:
- `src/pre_commit_terraform/` is a standalone CLI app, not a helper library for bash
- Each subcommand is a module with `invoke_cli_app()` + `populate_argument_parser()` + `CLI_SUBCOMMAND_NAME`
- Currently only `terraform-docs-replace` subcommand exists
- Adding a new Python subcommand: create module → register in `_cli_subcommands.py` → add hook entry in `.pre-commit-hooks.yaml`

New shell hooks: use `_common.sh` helpers, define `per_dir_hook_unique_part`, never ad-hoc argument splitting.

## Adding a new hook

Read `.github/CONTRIBUTING.md` — it covers the full checklist (Dockerfile, container structure tests, `.pre-commit-hooks.yaml`, hook file, docs).

## Testing

- Tests live in `tests/pytest/` and use `pytest`, run via `tox`
- Coverage config: `.coveragerc`
- For how to run tests and pre-commit checks locally, see `.github/CONTRIBUTING.md`

## Linters

This repo enforces style via pre-commit (`.pre-commit-config.yaml`) — install and run it before committing. Linters cover:
- **Python**: `ruff` (single quotes, type hints required) + `mypy`
- **Shell**: `shfmt` + `shellcheck` — no suppression without comment

## AI policy

This repo has an `AI_POLICY.md` in `.github/`. When helping a contributor open a PR or issue, point them to it. Key points: contributor owns every line, slop gets closed without discussion.

## Repo rules

- Hook args parsing: use `_common.sh` helpers, never ad-hoc argument splitting
- Do not hand-edit `CHANGELOG.md` — managed by release tooling (`.releaserc.json`)

## CI

PRs trigger `.github/workflows/ci-cd.yml`:
- Runs pre-commit hooks
- Runs pytest via tox across Python versions
- Builds and tests Docker image
- Release cut on merge to `master` via semantic-release

## Skill routing

Load these skills when their triggers match.

| Task | Skill |
| --- | --- |
| Creating a new skill: registering in AGENTS.md, choosing script vs SKILL.md | `adding-skills` |
| Create a commit, GitHub issue, or PR | `git-workflow` |
