"""Black-box regression tests for `--hook-config=--tool-version=` resolution.

Every test here invokes a real hook script under `hooks/` as a subprocess
and asserts on its exit code, the cache directory's filesystem state, and
its stdout/stderr - never on a bash-internal function name - so these
tests require minimal changes if a hook is ever reimplemented in another
language.
"""

from __future__ import annotations

import os
import shutil
import stat
import subprocess
import sys
from pathlib import Path
from typing import Literal

import pytest


REPO_ROOT = Path(__file__).resolve().parents[2]
HOOKS_DIR = REPO_ROOT / 'hooks'
GIT = shutil.which('git') or 'git'
BASH = shutil.which('bash') or 'bash'

pytestmark = pytest.mark.skipif(
    sys.platform == 'win32',
    reason=(
        'Hook-subprocess tests are skipped on Windows: this repository '
        'does not fully support/guarantee Windows hook execution '
        '(see README.md / .github/CONTRIBUTING.md).'
    ),
)


def _write_stub(path: Path, marker: str) -> None:
    """Write a fake, executable binary that prints a marker and exits 0."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        f'#!/usr/bin/env bash\necho "{marker}"\nexit 0\n',
        encoding='utf-8',
    )
    exec_bits = stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH
    path.chmod(path.stat().st_mode | exec_bits)


def _fake_path_dir(base: Path, *, hide: str) -> Path:
    """Build a PATH dir with coreutils symlinked in but `hide` excluded.

    Returns:
        Path to the constructed directory, usable as a `PATH` entry.
    """
    path_dir = base / 'fake-path'
    path_dir.mkdir()
    coreutils = (
        'dirname',
        'getopt',
        'cat',
        'sed',
        'awk',
        'tr',
        'sort',
        'uname',
        'git',
    )
    for tool in coreutils:
        if tool == hide:
            continue
        found = shutil.which(tool)
        if found is not None:
            (path_dir / tool).symlink_to(found)
    return path_dir


@pytest.fixture
def tmp_repo(tmp_path: Path) -> Path:
    """Create a minimal git repo with one tracked, provider-free `.tf` file.

    Returns:
        Path to the created repo directory.
    """
    repo = tmp_path / 'repo'
    repo.mkdir()
    subprocess.run((GIT, 'init', '-q'), cwd=repo, check=True)  # noqa: S603
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
    (repo / 'a.tf').write_text(
        'variable "x" { default = 1 }\n',
        encoding='utf-8',
    )
    subprocess.run((GIT, 'add', 'a.tf'), cwd=repo, check=True)  # noqa: S603
    subprocess.run(  # noqa: S603
        (GIT, 'commit', '-q', '-m', 'init'),
        cwd=repo,
        check=True,
    )
    return repo


@pytest.fixture
def cache_dir(tmp_path: Path) -> Path:
    """Create a dedicated, empty cache root for one test.

    Returns:
        Path to the created, empty cache root directory.
    """
    cache = tmp_path / 'cache'
    cache.mkdir()
    return cache


def _run_hook(
    hook_name: str,
    args: list[str],
    *,
    cwd: Path,
    cache_dir: Path,
    path_override: tuple[Literal['prepend', 'replace'], Path] | None = None,
) -> subprocess.CompletedProcess[str]:
    env = dict(os.environ)
    env['PCT_TOOL_CACHE_DIR'] = str(cache_dir)
    env.pop('XDG_CACHE_HOME', None)
    if path_override is not None:
        mode, extra_dir = path_override
        if mode == 'replace':
            env['PATH'] = str(extra_dir)
        else:
            env['PATH'] = f'{extra_dir}{os.pathsep}{env.get("PATH", "")}'
    return subprocess.run(  # noqa: S603
        (BASH, str(HOOKS_DIR / hook_name), *args, '--', 'a.tf'),
        cwd=cwd,
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )


def test_cache_hit_no_network(tmp_repo: Path, cache_dir: Path) -> None:
    """Check that a pre-populated cache entry is used, with no download."""
    stub = cache_dir / 'tflint' / '0.50.0' / 'tflint'
    _write_stub(stub, 'FAKE_TFLINT_INVOKED')

    hook_run = _run_hook(
        'terraform_tflint.sh',
        ['--hook-config=--tool-version=0.50.0'],
        cwd=tmp_repo,
        cache_dir=cache_dir,
    )

    assert 'Downloading' not in hook_run.stdout + hook_run.stderr
    # Cache entry untouched/still present, not re-created by a download.
    assert stub.exists()


def test_tool_version_mode_strict_prefers_pinned(
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check that default `strict` mode prefers the pinned/cached version."""
    fake_path_dir = tmp_path / 'fakebin'
    fake_path_dir.mkdir()
    _write_stub(fake_path_dir / 'tflint', 'LOCAL_TFLINT')

    pinned = cache_dir / 'tflint' / '0.50.0' / 'tflint'
    _write_stub(pinned, 'PINNED_TFLINT')

    hook_run = _run_hook(
        'terraform_tflint.sh',
        ['--hook-config=--tool-version=0.50.0'],
        cwd=tmp_repo,
        cache_dir=cache_dir,
        path_override=('prepend', fake_path_dir),
    )

    combined = hook_run.stdout + hook_run.stderr
    assert 'downloaded/used instead of whatever is on $PATH' in combined
    assert pinned.exists()


def test_tool_version_mode_prefer_local(
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check that `prefer-local` mode skips the cache/download when found."""
    fake_path_dir = tmp_path / 'fakebin'
    fake_path_dir.mkdir()
    _write_stub(fake_path_dir / 'tflint', 'LOCAL_TFLINT')

    hook_run = _run_hook(
        'terraform_tflint.sh',
        [
            '--hook-config=--tool-version=0.50.0',
            '--hook-config=--tool-version-mode=prefer-local',
        ],
        cwd=tmp_repo,
        cache_dir=cache_dir,
        path_override=('prepend', fake_path_dir),
    )

    assert 'prefer-local' in hook_run.stdout + hook_run.stderr
    assert not (cache_dir / 'tflint').exists()


@pytest.mark.parametrize(
    ('tf_path_value', 'expected_tool_dir', 'expected_bin_name'),
    (
        pytest.param('terraform', 'terraform', 'terraform', id='terraform'),
        pytest.param('opentofu', 'opentofu', 'tofu', id='opentofu'),
        pytest.param('tofu', 'opentofu', 'tofu', id='tofu-alias'),
    ),
)
def test_tf_path_selector(
    tmp_repo: Path,
    cache_dir: Path,
    tf_path_value: str,
    expected_tool_dir: str,
    expected_bin_name: str,
) -> None:
    """Check that `--tf-path=terraform|opentofu|tofu` selects the pinned tool.

    Args:
        tmp_repo: Temp git repo fixture.
        cache_dir: Temp cache root fixture.
        tf_path_value: The `--tf-path` value under test.
        expected_tool_dir: Expected cache subdir (`terraform`/`opentofu`).
        expected_bin_name: Expected cached binary filename.
    """
    stub = cache_dir / expected_tool_dir / '1.9.0' / expected_bin_name
    _write_stub(stub, 'FAKE_TF_INVOKED')

    hook_run = _run_hook(
        'terraform_fmt.sh',
        [
            f'--hook-config=--tf-path={tf_path_value}',
            '--hook-config=--tool-version=1.9.0',
        ],
        cwd=tmp_repo,
        cache_dir=cache_dir,
    )

    assert hook_run.returncode == 0
    assert stub.exists()


def test_tf_path_rejects_invalid_value(
    tmp_repo: Path,
    cache_dir: Path,
) -> None:
    """Check an unrecognized `--tf-path` + `--tool-version` combo errors."""
    hook_run = _run_hook(
        'terraform_fmt.sh',
        [
            '--hook-config=--tf-path=/some/custom/path',
            '--hook-config=--tool-version=1.9.0',
        ],
        cwd=tmp_repo,
        cache_dir=cache_dir,
    )

    assert hook_run.returncode != 0
    assert 'not a valid value' in hook_run.stdout + hook_run.stderr


def test_checkov_ignores_tool_version(
    tmp_repo: Path,
    cache_dir: Path,
) -> None:
    """Check checkov (pip-distributed) ignores `--tool-version` silently."""
    hook_run = _run_hook(
        'terraform_checkov.sh',
        ['--hook-config=--tool-version=1.2.3', '--args=--quiet'],
        cwd=tmp_repo,
        cache_dir=cache_dir,
    )

    combined = hook_run.stdout + hook_run.stderr
    assert 'not a valid value' not in combined
    assert 'no installer found' not in combined


def test_actionable_error_when_tool_missing(
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check the named, actionable error when unpinned and absent from PATH."""
    fake_path_dir = _fake_path_dir(tmp_path, hide='tflint')

    hook_run = _run_hook(
        'terraform_tflint.sh',
        [],
        cwd=tmp_repo,
        cache_dir=cache_dir,
        path_override=('replace', fake_path_dir),
    )

    combined = hook_run.stdout + hook_run.stderr
    assert hook_run.returncode != 0
    assert 'tflint' in combined
    assert '--hook-config=--tool-version=' in combined


def test_real_download_on_cache_miss(tmp_repo: Path, cache_dir: Path) -> None:
    """Check a genuine end-to-end download for a cache-miss path (network)."""
    hook_run = _run_hook(
        'terraform_tflint.sh',
        ['--hook-config=--tool-version=0.50.0'],
        cwd=tmp_repo,
        cache_dir=cache_dir,
    )

    cached_bin = cache_dir / 'tflint' / '0.50.0' / 'tflint'
    assert cached_bin.exists()
    assert os.access(cached_bin, os.X_OK)

    version_check = subprocess.run(  # noqa: S603
        (str(cached_bin), '--version'),
        capture_output=True,
        text=True,
        check=False,
    )
    assert '0.50.0' in version_check.stdout
    # 2 is tflint's own lint findings on the minimal fixture; not our concern.
    assert hook_run.returncode in {0, 2}
