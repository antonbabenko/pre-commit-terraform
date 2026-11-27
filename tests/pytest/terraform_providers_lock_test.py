"""Regression test for `--mode` parsing in `terraform_providers_lock`.

`--hook-config` values are collected in `_common.sh` as `"$1;"` and later
re-split on `;` after `"${HOOK_CONFIG[*]}"` joined them with spaces, so every
entry after the first arrives with a leading space. `terraform_providers_lock`
compared `${config[0]}` verbatim against `--mode`, which meant the flag was
only recognised when it happened to be the first `--hook-config` argument.
In any other position the hook fell into the no-mode branch: it printed the
deprecation notice and ran `terraform providers lock` even though the mode
asked it not to.

The test drives the real hook script as a subprocess, against a lockfile that
already carries all requested platform checksums, with a stub Terraform binary
that records every invocation. `--mode=check-lockfile-is-cross-platform` then
has exactly one correct behaviour - exit 0 without locking any provider - in
either argument order.
"""

from __future__ import annotations

import os
import shutil
import stat
import subprocess
import sys
import tempfile
from pathlib import Path

import pytest


REPO_ROOT = Path(__file__).resolve().parents[2]
HOOKS_DIR = REPO_ROOT / 'hooks'
HOOK_NAME = 'terraform_providers_lock.sh'
# The hook only inspects files matching the manifest's
# `(\.terraform\.lock\.hcl)$` pattern.
LOCKFILE_NAME = '.terraform.lock.hcl'

GIT = shutil.which('git') or 'git'
BASH = shutil.which('bash') or 'bash'

MODE = 'check-lockfile-is-cross-platform'
MODE_ARG = f'--hook-config=--mode={MODE}'
# Any other `--hook-config` key works here; `--parallelism-limit` is the one
# users most often already have in `args:`, so it is the realistic neighbour.
OTHER_CONFIG_ARG = '--hook-config=--parallelism-limit=1'

# Passed the way README documents them, so the hook counts two platforms and
# `check-lockfile-is-cross-platform` has real checksums to compare against.
PLATFORMS = ('linux_amd64', 'darwin_arm64')

# hooks/terraform_providers_lock.sh: the notice printed when `--mode` was not
# recognised. Its presence is the second, user-visible symptom of the bug.
DEPRECATION_MSG = "We introduced '--mode' flag for this hook"

# One provider, one `h1:` per requested platform, plus the `zh:` line every
# real lockfile carries - exactly what `lockfile_contains_all_needed_sha`
# accepts, so only the `--mode` parsing decides whether Terraform runs.
LOCKFILE = """\
provider "registry.terraform.io/hashicorp/null" {
  version     = "3.2.2"
  constraints = "~> 3.0"
  hashes = [
    "h1:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa=",
    "h1:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb=",
    "zh:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
  ]
}
"""

HOOK_TIMEOUT_SECONDS = 300

pytestmark = pytest.mark.skipif(
    sys.platform == 'win32',
    reason=(
        'Hook-subprocess tests are skipped on Windows: this repository '
        'does not fully support/guarantee Windows hook execution '
        '(see README.md / .github/CONTRIBUTING.md).'
    ),
)


def _write_recording_stub(  # pragma: win32 no cover
    path: Path,
    log_path: Path,
) -> None:
    """Write a fake Terraform binary that records its argv and exits 0.

    Args:
        path: Location to create the executable stub at.
        log_path: File the stub appends each invocation's arguments to.
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        f'#!/usr/bin/env bash\nprintf "%s\\n" "$*" >> "{log_path}"\nexit 0\n',
        encoding='utf-8',
    )
    exec_bits = stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH
    path.chmod(path.stat().st_mode | exec_bits)


@pytest.fixture
def lock_repo(tmp_path: Path) -> Path:  # pragma: win32 no cover
    """Create a git repo holding a fully cross-platform lockfile.

    Args:
        tmp_path: Pytest-provided temporary directory.

    Returns:
        Path to the created repository.
    """
    repo = tmp_path / 'repo'
    repo.mkdir()
    # `--template=` disables Git's init templates, which this project's own
    # README suggests pointing at a directory with pre-commit installed -
    # that would otherwise install and run a real hook on commit below.
    subprocess.run(  # noqa: S603
        (GIT, 'init', '--quiet', '--template=', '--initial-branch=main'),
        cwd=repo,
        check=True,
    )
    subprocess.run(  # noqa: S603
        (GIT, 'config', 'user.email', 't@t.com'),
        cwd=repo,
        check=True,
    )
    subprocess.run(  # noqa: S603
        (GIT, 'config', 'user.name', 't'),
        cwd=repo,
        check=True,
    )
    (repo / LOCKFILE_NAME).write_text(LOCKFILE, encoding='utf-8')
    (repo / 'main.tf').write_text(
        'resource "null_resource" "a" {}\n',
        encoding='utf-8',
    )
    subprocess.run((GIT, 'add', '.'), cwd=repo, check=True)  # noqa: S603
    subprocess.run(  # noqa: S603
        (GIT, 'commit', '--quiet', '--no-verify', '-m', 'init'),
        cwd=repo,
        check=True,
    )
    return repo


def _run_hook(  # pragma: win32 no cover
    hook_config_args: tuple[str, ...],
    *,
    cwd: Path,
    bin_dir: Path,
    log_path: Path,
) -> subprocess.CompletedProcess[str]:
    """Invoke the hook on the lockfile with the given `--hook-config` order.

    Args:
        hook_config_args: `--hook-config` values, in the order to pass them.
        cwd: Repository to run the hook from.
        bin_dir: Directory holding the stub Terraform, prepended to `PATH`.
        log_path: File the stub records invocations to.

    Returns:
        The completed process, with stderr folded into `.stdout`.
    """
    hook_path = HOOKS_DIR / HOOK_NAME
    if not hook_path.is_file():  # pragma: no cover
        # `hooks/` ships only in the sdist, so a packaging regression must
        # fail with a pointed message rather than a confusing mismatch.
        pytest.fail(f'Hook script not found: {hook_path}')
    env = {
        'PATH': f'{bin_dir}{os.pathsep}{os.environ["PATH"]}',
        'HOME': os.environ.get('HOME', ''),
        'TMPDIR': os.environ.get('TMPDIR', tempfile.gettempdir()),
        'LC_ALL': 'C',
        # Keeps `common::colorify` output plain, so a substring assertion on
        # the deprecation notice is not defeated by ANSI escapes.
        'PRE_COMMIT_COLOR': 'never',
        'TF_STUB_LOG': str(log_path),
    }
    platform_args = tuple(
        f'--args=-platform={platform}' for platform in PLATFORMS
    )
    return subprocess.run(  # noqa: S603
        (
            BASH,
            str(hook_path),
            *hook_config_args,
            *platform_args,
            '--',
            LOCKFILE_NAME,
        ),
        cwd=cwd,
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        check=False,
        timeout=HOOK_TIMEOUT_SECONDS,
    )


@pytest.mark.parametrize(
    'mode_position',
    (
        pytest.param('first', id='mode-first'),
        pytest.param('last', id='mode-second'),
    ),
)
def test_mode_is_honoured_regardless_of_position(  # pragma: win32 no cover
    lock_repo: Path,
    tmp_path: Path,
    mode_position: str,
) -> None:
    """Check `--mode` is parsed whether or not another config precedes it.

    Args:
        lock_repo: Repo fixture with a fully populated lockfile.
        tmp_path: Pytest-provided temporary directory.
        mode_position: Where `--mode` sits among the `--hook-config` args.
    """
    bin_dir = tmp_path / 'bin'
    log_path = tmp_path / 'terraform-invocations.log'
    # Created up front so the assertion below reads it unconditionally: an
    # `exists()` guard would leave one branch unexecuted under the suite's
    # 100%-branch-coverage requirement.
    log_path.write_text('', encoding='utf-8')
    _write_recording_stub(bin_dir / 'terraform', log_path)

    hook_config_args = (
        (MODE_ARG, OTHER_CONFIG_ARG)
        if mode_position == 'first'
        else (OTHER_CONFIG_ARG, MODE_ARG)
    )

    hook_run = _run_hook(
        hook_config_args,
        cwd=lock_repo,
        bin_dir=bin_dir,
        log_path=log_path,
    )

    combined = hook_run.stdout
    recorded = log_path.read_text(encoding='utf-8')
    assert not recorded, combined
    assert DEPRECATION_MSG not in combined, combined
    assert hook_run.returncode == 0, combined
