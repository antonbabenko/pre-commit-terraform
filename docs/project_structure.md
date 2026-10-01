# Project structure

This is a map of the repository for contributors. Hook *usage* stays in the [README](../README.md). How to add a hook, run tests, and open a PR is in [`.github/CONTRIBUTING.md`](../.github/CONTRIBUTING.md).

## Layout

| Path | Role |
| --- | --- |
| `hooks/` | Bash entry points (`<hook_name>.sh`) and shared `_common.sh` |
| `src/pre_commit_terraform/` | Python package: CLI parsing, env expansion, `__GIT_WORKING_DIR__`, `terraform_docs_replace` |
| `tests/pytest/` | Python unit tests (`pytest`) |
| `tools/entrypoint.sh` | Docker image entrypoint |
| `tools/install/` | Per-tool install scripts used when building the Docker image |
| `dependencies/lock-files/` | Pinned Python constraints for reproducible image builds |
| `.pre-commit-hooks.yaml` | Hook definitions consumed by the [pre-commit framework](https://pre-commit.com/) |
| `pyproject.toml` / `hatch.toml` | Python project and build config |
| `tox.ini` | Test environment matrix |
| `.github/workflows/ci-cd.yml` | PR checks, tox, image build; release on merge to `master` |

## Hook types

**Shell hooks** (most of them) live in `hooks/<hook_name>.sh`:

- Source `_common.sh` for `--args`, `--hook-config`, `--env-vars`, env expansion, `__GIT_WORKING_DIR__`, parallelism, and `terraform init`
- Define `per_dir_hook_unique_part()` for per-directory work
- Call `common::per_dir_hook` instead of splitting arguments by hand

**Python hooks** run as `python -m pre_commit_terraform <subcommand>`:

- Modules live under `src/pre_commit_terraform/`
- Each subcommand implements `invoke_cli_app()`, `populate_argument_parser()`, and `CLI_SUBCOMMAND_NAME`
- Register new subcommands in `_cli_subcommands.py` and add a hook entry in `.pre-commit-hooks.yaml`

## Local checks

Install pre-commit and run the repo's own hooks before you push. Python tests run with `tox`. Do not hand-edit `CHANGELOG.md`; releases own that file.
