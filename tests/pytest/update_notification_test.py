"""Black-box tests for the update notification feature.

Tests the `common::maybe_notify_new_version` function added to
`hooks/_common.sh`. Every test invokes a real hook script as a subprocess
and asserts on its
output, exit code, and cache directory state - never on bash-internal
function names.

NOTE: the module-level `pytestmark` skip leaves every function body below
unexecuted on Windows, and `covdefaults` gates coverage at 100%, so every
module-level `def` in this file needs a `# pragma: win32 no cover`.
"""

from __future__ import annotations

import os
import shutil
import stat
import subprocess
import sys
import tempfile
import time
from pathlib import Path

import pytest


REPO_ROOT = Path(__file__).resolve().parents[2]
HOOKS_DIR = REPO_ROOT / 'hooks'


# Both are resolved against *this* process' `PATH` by `execvp`, not against
# the `PATH` handed to the subprocess - which is what keeps a sandboxed
# `PATH` (see `_sandbox_path_dir`) from breaking the interpreter itself
# while still hiding wrapped CLI tools from the hook under test.
GIT = shutil.which('git') or 'git'
BASH = shutil.which('bash') or 'bash'

_SECONDS_PER_HOUR = 3600
_SECONDS_PER_DAY = 86400

# Diagnostic messages emitted by `common::colorify` in `hooks/_common.sh`.
OUTDATED_MSG = 'is outdated; latest is'
UNTAGGED_MSG = 'pinned to a non-release commit; latest release is'
# Quote-character-agnostic on purpose: `common::colorify` messages have
# been observed with both `'single'` and `"double"` quoting around the
# command names depending on how the file was last (re)formatted, so
# these check the command text itself, never the surrounding punctuation.
AUTOUPDATE_MSG = 'pre-commit autoupdate --freeze'
PREK_UPDATE_MSG = 'prek update --freeze'
TIMEOUT_MSG = 'Update check timed out.'
FAILED_MSG = 'Update check failed'
SKIP_SUGGESTION_MSG = 'Set CI=true or PCT_SKIP_UPDATE_CHECK=true to skip.'

HOOK_TIMEOUT_SECONDS = 30

pytestmark = pytest.mark.skipif(
    sys.platform == 'win32',
    reason=(
        'Hook-subprocess tests are skipped on Windows: this repository '
        'does not fully support/guarantee Windows hook execution '
        '(see README.md / .github/CONTRIBUTING.md).'
    ),
)


class _GitDispatcherStub:
    """A `git` dispatcher stub that forwards all commands except `ls-remote`.

    When placed ahead of the real `git` on `$PATH`, this stub intercepts
    `git ls-remote` calls and returns canned fixture data, while forwarding
    all other subcommands (`rev-parse`, `ls-files`, etc.) to the real `git`.
    This keeps the hook's genuine git usage real while making the remote
    tag query fully deterministic and network-free.
    """

    def __init__(self, tmp_path: Path) -> None:
        """Create a dispatcher stub directory.

        Args:
            tmp_path: Base temporary directory to create the stub in.
        """
        self.stub_dir = tmp_path / 'git-dispatcher'
        self.stub_dir.mkdir()
        self.stub_path = self.stub_dir / 'git'

        # Write the dispatcher script
        self.stub_path.write_text(
            '#!/usr/bin/env bash\n'
            'set -eo pipefail\n'
            '\n'
            'if [[ "$1" == "ls-remote" ]]; then\n'
            '  # Intercept ls-remote calls\n'
            '  if [[ -f "${0}.ls-remote-output" ]]; then\n'
            '    cat "${0}.ls-remote-output"\n'
            '    if [[ -f "${0}.ls-remote-exitcode" ]]; then\n'
            '      exit_code=$(cat "${0}.ls-remote-exitcode")\n'
            '      exit "$exit_code"\n'
            '    else\n'
            '      exit 0\n'
            '    fi\n'
            '  else\n'
            '    # Default: empty tag list\n'
            '    exit 0\n'
            '  fi\n'
            'else\n'
            '  # Forward all other commands to the real git\n'
            '  exec "$(dirname "$0")/real-git" "$@"\n'
            'fi\n',
            encoding='utf-8',
        )
        exec_bits = stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH
        self.stub_path.chmod(self.stub_path.stat().st_mode | exec_bits)

        # Symlink to real git
        real_git_dir = self.stub_dir / 'real-git'
        real_git_dir.symlink_to(GIT)

    def set_ls_remote_output(self, output: str, exit_code: int = 0) -> None:
        """Configure the canned `ls-remote` output and exit code.

        Args:
            output: The exact stdout `git ls-remote` should return.
            exit_code: Exit code (0 for success, non-zero for failure).
        """
        stub_dir, stub_name = self.stub_path.parent, self.stub_path.name
        (stub_dir / f'{stub_name}.ls-remote-output').write_text(
            output,
            encoding='utf-8',
        )
        (stub_dir / f'{stub_name}.ls-remote-exitcode').write_text(
            str(exit_code),
            encoding='utf-8',
        )

    @property
    def path_entry(self) -> str:
        """The directory path to prepend to `PATH`."""
        return str(self.stub_dir)


def _write_stub(path: Path, marker: str) -> None:  # pragma: win32 no cover
    """Write a fake, executable binary that prints a marker and exits 0."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        f'#!/usr/bin/env bash\necho "{marker}"\nexit 0\n',
        encoding='utf-8',
    )
    exec_bits = stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH
    path.chmod(path.stat().st_mode | exec_bits)


def _create_terraform_stub(dispatcher: _GitDispatcherStub) -> None:
    """Create a terraform stub in the dispatcher directory.

    The stub will be found before any real terraform in PATH,
    allowing hooks that require terraform/tofu to succeed.
    """
    terraform_stub = dispatcher.stub_dir / 'terraform'
    _write_stub(terraform_stub, 'TERRAFORM_STUB')


def _sandbox_path_dir(base: Path) -> Path:  # pragma: win32 no cover
    """Build a `PATH` dir with coreutils but no wrapped CLI tool.

    Reuses the same list of required/optional tools as `tool_version_test.py`.

    Returns:
        Path to the constructed directory, usable as a `PATH` entry.
    """
    # Same tool lists as tool_version_test.py
    sandbox_required_tools = (
        'awk',
        'basename',
        'bash',
        'cat',
        'cut',
        'dirname',
        'env',
        'grep',
        'head',
        'mkdir',
        'mktemp',
        'rm',
        'sed',
        'sort',
        'tail',
        'timeout',
        'tr',
        'uname',
        'wc',
        'git',
    )
    sandbox_optional_tools = (
        'chmod',
        'cp',
        'curl',
        'date',
        'find',
        'getopt',
        'id',
        'ln',
        'ls',
        'mv',
        'nproc',
        'printf',
        'readlink',
        'realpath',
        'seq',
        'stat',
        'sysctl',
        'tar',
        'tee',
        'touch',
        'uniq',
        'unzip',
        'xargs',
    )

    path_dir = base / 'sandbox-path'
    path_dir.mkdir()
    for tool in sandbox_required_tools:
        found = shutil.which(tool)
        assert found is not None, f'{tool!r} not found on PATH'
        (path_dir / tool).symlink_to(found)
    for optional_tool in sandbox_optional_tools:
        optional_found = shutil.which(optional_tool)
        if optional_found is not None:  # pragma: no branch
            (path_dir / optional_tool).symlink_to(optional_found)
    return path_dir


def _hook_env(  # pragma: win32 no cover
    cache_env: dict[str, str],
    path: str,
    extra_env: dict[str, str] | None = None,
) -> dict[str, str]:
    """Build a minimal, hermetic environment for a hook subprocess.

    Inheriting `os.environ` wholesale would let `PCT_TFPATH`,
    `TERRAGRUNT_TFPATH`, `PRE_COMMIT_COLOR` or `TF_*` from the developer's
    shell change what these tests resolve, so only an explicit allowlist
    is forwarded.

    Args:
        cache_env: Variables that decide the cache root -
            `PCT_TOOL_CACHE_DIR`, or `XDG_CACHE_HOME`/`HOME` when
            exercising the fallbacks. Merged last, so it can override
            `HOME`.
        path: Value for `PATH`.
        extra_env: Additional environment variables to include.

    Returns:
        The environment mapping to hand to `subprocess.run`.
    """
    env = {
        'PATH': path,
        'HOME': os.environ.get('HOME', ''),
        'TMPDIR': os.environ.get('TMPDIR', tempfile.gettempdir()),
        'LC_ALL': 'C',
        # `common::colorify` wraps every message in ANSI escapes unless
        # this is set; plain text keeps substring assertions honest.
        'PRE_COMMIT_COLOR': 'never',
        # Read directly by `tools/install/_common.sh`. Forwarded as an
        # empty string when absent, which that script treats as unset.
        'GITHUB_TOKEN': os.environ.get('GITHUB_TOKEN', ''),
        **(extra_env or {}),
        **cache_env,
    }
    return env  # noqa: RET504 - keep the built value visible for review


def _pct_cache_env(  # pragma: win32 no cover
    cache_dir: Path,
) -> dict[str, str]:
    """Point the cache root straight at `cache_dir`.

    Returns:
        A `PCT_TOOL_CACHE_DIR` mapping for `_hook_env`.
    """
    return {'PCT_TOOL_CACHE_DIR': str(cache_dir)}


@pytest.fixture
def tmp_repo(tmp_path: Path) -> Path:  # pragma: win32 no cover
    """Create a minimal git repo with one tracked, provider-free `.tf` file.

    Returns:
        Path to the created repo directory.
    """
    repo = tmp_path / 'repo'
    repo.mkdir()
    # `--template=` disables Git's init templates: this project's own
    # README tells users to set `init.templateDir` to a directory with
    # pre-commit installed, which would otherwise install a real
    # pre-commit hook into this throwaway repo and run it on commit.
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
    (repo / 'a.tf').write_text(
        'variable "x" { default = 1 }\n',
        encoding='utf-8',
    )
    subprocess.run((GIT, 'add', 'a.tf'), cwd=repo, check=True)  # noqa: S603
    subprocess.run(  # noqa: S603
        (GIT, 'commit', '--quiet', '--no-verify', '-m', 'init'),
        cwd=repo,
        check=True,
    )
    return repo


@pytest.fixture
def cache_dir(tmp_path: Path) -> Path:  # pragma: win32 no cover
    """Create a dedicated, empty cache root for one test.

    Returns:
        Path to the created, empty cache root directory.
    """
    cache = tmp_path / 'cache'
    cache.mkdir()
    return cache


def _run_hook(  # pragma: win32 no cover
    hook_name: str,
    args: list[str],
    *,
    cwd: Path,
    env: dict[str, str],
) -> subprocess.CompletedProcess[str]:
    """Invoke a hook script on the single `a.tf` file of a temp repo.

    Returns:
        The completed process, with stderr folded into `.stdout`.
    """
    hook_path = HOOKS_DIR / hook_name
    if not hook_path.is_file():  # pragma: no cover
        pytest.fail(f'Hook script not found: {hook_path}')
    # `common::colorify` writes every diagnostic to stderr while a wrapped
    # tool's own output goes to stdout, so the two are merged at the OS
    # level to give each caller one ready-to-grep string.
    return subprocess.run(  # noqa: S603
        (BASH, str(hook_path), *args, '--', 'a.tf'),
        cwd=cwd,
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        check=False,
        timeout=HOOK_TIMEOUT_SECONDS,
    )


# Sample git ls-remote output for testing
SAMPLE_LS_REMOTE_OUTPUT = """\
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa	refs/tags/v1.0.0
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb	refs/tags/v1.1.0
cccccccccccccccccccccccccccccccccccccccc	refs/tags/v1.2.0
dddddddddddddddddddddddddddddddddddddddd	refs/tags/v1.3.0
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee	refs/tags/v1.4.0
"""


def test_ci_set_skips_check(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check `$CI` set → no network attempt, cache file untouched."""
    dispatcher = _GitDispatcherStub(tmp_path)
    dispatcher.set_ls_remote_output(SAMPLE_LS_REMOTE_OUTPUT)
    _create_terraform_stub(dispatcher)

    # Create a sandboxed PATH with the dispatcher first
    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    path_with_dispatcher = f'{dispatcher.path_entry}:{sandbox_path_dir}'

    hook_run = _run_hook(
        'terraform_fmt.sh',
        [],
        cwd=tmp_repo,
        env=_hook_env(
            _pct_cache_env(cache_dir),
            path_with_dispatcher,
            {'CI': 'true'},
        ),
    )

    combined = hook_run.stdout
    assert OUTDATED_MSG not in combined, combined
    assert UNTAGGED_MSG not in combined, combined
    assert AUTOUPDATE_MSG not in combined, combined
    assert TIMEOUT_MSG not in combined, combined
    assert FAILED_MSG not in combined, combined

    # Cache file should not exist (check was skipped without attempt)
    cache_file = cache_dir / '.last_update_check'
    assert not cache_file.exists(), f'Cache file missing check: {cache_file}'

    # Hook should still run its real work
    assert hook_run.returncode == 0, combined


def test_pct_skip_update_check_set_skips_check(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check `$PCT_SKIP_UPDATE_CHECK` set → no attempt, cache untouched."""
    dispatcher = _GitDispatcherStub(tmp_path)
    dispatcher.set_ls_remote_output(SAMPLE_LS_REMOTE_OUTPUT)
    _create_terraform_stub(dispatcher)

    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    path_with_dispatcher = f'{dispatcher.path_entry}:{sandbox_path_dir}'

    hook_run = _run_hook(
        'terraform_fmt.sh',
        [],
        cwd=tmp_repo,
        env=_hook_env(
            _pct_cache_env(cache_dir),
            path_with_dispatcher,
            {'PCT_SKIP_UPDATE_CHECK': 'true'},
        ),
    )

    combined = hook_run.stdout
    assert OUTDATED_MSG not in combined, combined
    assert UNTAGGED_MSG not in combined, combined
    assert AUTOUPDATE_MSG not in combined, combined
    assert TIMEOUT_MSG not in combined, combined
    assert FAILED_MSG not in combined, combined

    cache_file = cache_dir / '.last_update_check'
    assert not cache_file.exists(), f'Cache file missing check: {cache_file}'
    assert hook_run.returncode == 0, combined


def test_fresh_cache_skips_check(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check fresh cache file (< 7 days old) → no network attempt."""
    dispatcher = _GitDispatcherStub(tmp_path)
    dispatcher.set_ls_remote_output(SAMPLE_LS_REMOTE_OUTPUT)
    _create_terraform_stub(dispatcher)

    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    path_with_dispatcher = f'{dispatcher.path_entry}:{sandbox_path_dir}'

    # Create a fresh cache file (1 hour old)
    cache_file = cache_dir / '.last_update_check'
    cache_file.parent.mkdir(parents=True, exist_ok=True)
    one_hour_ago = int(time.time()) - _SECONDS_PER_HOUR
    cache_file.write_text(str(one_hour_ago), encoding='utf-8')

    hook_run = _run_hook(
        'terraform_fmt.sh',
        [],
        cwd=tmp_repo,
        env=_hook_env(_pct_cache_env(cache_dir), path_with_dispatcher),
    )

    combined = hook_run.stdout
    assert OUTDATED_MSG not in combined, combined
    assert UNTAGGED_MSG not in combined, combined
    assert AUTOUPDATE_MSG not in combined, combined
    assert TIMEOUT_MSG not in combined, combined
    assert FAILED_MSG not in combined, combined

    # Cache file should still contain the original timestamp (not updated)
    assert cache_file.read_text(encoding='utf-8') == str(one_hour_ago)
    assert hook_run.returncode == 0, combined


def test_stale_cache_outdated_tag_nag(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check stale cache + pinned tag older than latest → nag printed."""
    dispatcher = _GitDispatcherStub(tmp_path)
    _create_terraform_stub(dispatcher)

    # Create empty commit and get its SHA
    subprocess.run(  # noqa: S603
        (GIT, 'commit', '--allow-empty', '-m', 'bump', '--date=2000-01-01'),
        cwd=tmp_repo,
        check=True,
    )
    head_rev_parse = subprocess.run(  # noqa: S603
        (GIT, 'rev-parse', 'HEAD'),
        cwd=tmp_repo,
        capture_output=True,
        text=True,
        check=True,
    )
    current_sha = head_rev_parse.stdout.strip()

    # Tag current HEAD as v1.3.0
    subprocess.run(  # noqa: S603
        (GIT, 'tag', '-f', 'v1.3.0'),
        cwd=tmp_repo,
        check=True,
    )

    # Update ls-remote output to include current SHA as v1.3.0
    ls_remote_output = SAMPLE_LS_REMOTE_OUTPUT.replace(
        'dddddddddddddddddddddddddddddddddddddddd',
        current_sha,
    )
    dispatcher.set_ls_remote_output(ls_remote_output)

    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    path_with_dispatcher = f'{dispatcher.path_entry}:{sandbox_path_dir}'

    # Create a stale cache file (8 days old)
    cache_file = cache_dir / '.last_update_check'
    cache_file.parent.mkdir(parents=True, exist_ok=True)
    eight_days_ago = int(time.time()) - (8 * _SECONDS_PER_DAY)
    cache_file.write_text(str(eight_days_ago), encoding='utf-8')

    hook_run = _run_hook(
        'terraform_fmt.sh',
        [],
        cwd=tmp_repo,
        env=_hook_env(_pct_cache_env(cache_dir), path_with_dispatcher),
    )

    combined = hook_run.stdout
    assert OUTDATED_MSG in combined, combined
    assert AUTOUPDATE_MSG in combined, combined
    assert PREK_UPDATE_MSG in combined, combined
    assert 'v1.3.0' in combined, combined
    assert 'v1.4.0' in combined, combined

    # Cache file should be updated to now (or very recent)
    new_timestamp = int(cache_file.read_text(encoding='utf-8'))
    assert new_timestamp > eight_days_ago
    assert hook_run.returncode == 0, combined


def test_stale_cache_untagged_nag(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check stale/absent cache + HEAD matches no tag → nag printed."""
    dispatcher = _GitDispatcherStub(tmp_path)
    dispatcher.set_ls_remote_output(SAMPLE_LS_REMOTE_OUTPUT)
    _create_terraform_stub(dispatcher)

    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    path_with_dispatcher = f'{dispatcher.path_entry}:{sandbox_path_dir}'

    # Create a stale cache file (8 days old)
    cache_file = cache_dir / '.last_update_check'
    cache_file.parent.mkdir(parents=True, exist_ok=True)
    eight_days_ago = int(time.time()) - (8 * _SECONDS_PER_DAY)
    cache_file.write_text(str(eight_days_ago), encoding='utf-8')

    hook_run = _run_hook(
        'terraform_fmt.sh',
        [],
        cwd=tmp_repo,
        env=_hook_env(_pct_cache_env(cache_dir), path_with_dispatcher),
    )

    combined = hook_run.stdout
    assert UNTAGGED_MSG in combined, combined
    assert AUTOUPDATE_MSG in combined, combined
    assert PREK_UPDATE_MSG in combined, combined
    assert 'v1.4.0' in combined, combined  # Latest tag should be mentioned

    # Cache file should be updated
    new_timestamp = int(cache_file.read_text(encoding='utf-8'))
    assert new_timestamp > eight_days_ago
    assert hook_run.returncode == 0, combined


def test_stale_cache_up_to_date_silent(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check stale/absent cache + pinned tag equals latest → no output."""
    dispatcher = _GitDispatcherStub(tmp_path)
    _create_terraform_stub(dispatcher)

    # Get current HEAD sha and tag it as v1.4.0 (latest)
    current_sha = subprocess.run(  # noqa: S603
        (GIT, 'rev-parse', 'HEAD'),
        cwd=tmp_repo,
        capture_output=True,
        text=True,
        check=True,
    ).stdout.strip()

    # Create ls-remote output with current HEAD as v1.4.0
    ls_remote_output = SAMPLE_LS_REMOTE_OUTPUT.replace(
        'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
        current_sha,
    )
    dispatcher.set_ls_remote_output(ls_remote_output)

    # Tag current HEAD as v1.4.0
    subprocess.run(  # noqa: S603
        (GIT, 'tag', '-f', 'v1.4.0'),
        cwd=tmp_repo,
        check=True,
    )

    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    path_with_dispatcher = f'{dispatcher.path_entry}:{sandbox_path_dir}'

    # Create a stale cache file (8 days old)
    cache_file = cache_dir / '.last_update_check'
    cache_file.parent.mkdir(parents=True, exist_ok=True)
    eight_days_ago = int(time.time()) - (8 * _SECONDS_PER_DAY)
    cache_file.write_text(str(eight_days_ago), encoding='utf-8')

    hook_run = _run_hook(
        'terraform_fmt.sh',
        [],
        cwd=tmp_repo,
        env=_hook_env(_pct_cache_env(cache_dir), path_with_dispatcher),
    )

    combined = hook_run.stdout
    assert OUTDATED_MSG not in combined, combined
    assert UNTAGGED_MSG not in combined, combined
    assert AUTOUPDATE_MSG not in combined, combined
    assert TIMEOUT_MSG not in combined, combined
    assert FAILED_MSG not in combined, combined

    # Cache file should still be updated (attempt was made, just silent)
    new_timestamp = int(cache_file.read_text(encoding='utf-8'))
    assert new_timestamp > eight_days_ago
    assert hook_run.returncode == 0, combined


def test_network_failure_warning(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check dispatcher stub makes `ls-remote` fail → warn notice printed."""
    dispatcher = _GitDispatcherStub(tmp_path)
    dispatcher.set_ls_remote_output('', exit_code=1)  # Non-zero exit
    _create_terraform_stub(dispatcher)

    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    path_with_dispatcher = f'{dispatcher.path_entry}:{sandbox_path_dir}'

    # Create a stale cache file
    cache_file = cache_dir / '.last_update_check'
    cache_file.parent.mkdir(parents=True, exist_ok=True)
    eight_days_ago = int(time.time()) - (8 * _SECONDS_PER_DAY)
    cache_file.write_text(str(eight_days_ago), encoding='utf-8')

    hook_run = _run_hook(
        'terraform_fmt.sh',
        [],
        cwd=tmp_repo,
        env=_hook_env(_pct_cache_env(cache_dir), path_with_dispatcher),
    )

    combined = hook_run.stdout
    assert FAILED_MSG in combined, combined
    assert SKIP_SUGGESTION_MSG in combined, combined
    assert 'exit 1' in combined, combined

    # Cache file should be updated (attempt was made, even though it failed)
    new_timestamp = int(cache_file.read_text(encoding='utf-8'))
    assert new_timestamp > eight_days_ago
    assert hook_run.returncode == 0, combined  # Hook's own work unaffected


def test_check_at_most_once_per_invocation(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check hook invoked across multiple dirs attempts check at most once."""
    dispatcher = _GitDispatcherStub(tmp_path)
    dispatcher.set_ls_remote_output(SAMPLE_LS_REMOTE_OUTPUT)
    _create_terraform_stub(dispatcher)

    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    path_with_dispatcher = f'{dispatcher.path_entry}:{sandbox_path_dir}'

    # Create multiple .tf files in different directories
    (tmp_repo / 'dir1').mkdir()
    (tmp_repo / 'dir2').mkdir()
    (tmp_repo / 'dir1' / 'a.tf').write_text('variable "x" { default = 1 }\n')
    (tmp_repo / 'dir2' / 'b.tf').write_text('variable "y" { default = 2 }\n')

    subprocess.run(  # noqa: S603
        (GIT, 'add', 'dir1/a.tf', 'dir2/b.tf'),
        cwd=tmp_repo,
        check=True,
    )
    subprocess.run(  # noqa: S603
        (GIT, 'commit', '--quiet', '--no-verify', '-m', 'add dirs'),
        cwd=tmp_repo,
        check=True,
    )

    # Run hook with both files (should trigger check once)
    hook_path = HOOKS_DIR / 'terraform_fmt.sh'
    multi_dir_run = subprocess.run(  # noqa: S603
        (BASH, str(hook_path), '--', 'dir1/a.tf', 'dir2/b.tf'),
        cwd=tmp_repo,
        env=_hook_env(_pct_cache_env(cache_dir), path_with_dispatcher),
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        check=False,
        timeout=HOOK_TIMEOUT_SECONDS,
    )

    combined = multi_dir_run.stdout
    # Should see the nag (untagged since HEAD matches no tag in the fixture)
    assert UNTAGGED_MSG in combined, combined
    assert AUTOUPDATE_MSG in combined, combined
    assert PREK_UPDATE_MSG in combined, combined

    # Count occurrences - should appear only once
    nag_count = combined.count(UNTAGGED_MSG)
    assert nag_count == 1, f'Nag appeared {nag_count} times, expected 1'

    # Cache file should exist (check was attempted)
    cache_file = cache_dir / '.last_update_check'
    assert cache_file.exists()
    assert multi_dir_run.returncode == 0, combined


def test_check_fires_without_per_dir_hook(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check the notice fires for a hook that never calls `per_dir_hook`.

    `terraform_wrapper_module_for_each.sh` has its own whole-repo flow and
    never calls `common::per_dir_hook` (see `hooks/_common.sh` -
    `common::maybe_notify_new_version` must run as a top-level statement
    in `_common.sh` itself, not from inside `common::per_dir_hook`, or
    this exact hook silently loses coverage). The hook's own tool
    (`hcledit`) is deliberately left unstubbed and its exit code is
    deliberately not asserted: only the notice's presence, printed
    before the hook ever reaches its own tool resolution, is under test.
    """
    dispatcher = _GitDispatcherStub(tmp_path)
    dispatcher.set_ls_remote_output(SAMPLE_LS_REMOTE_OUTPUT)

    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    path_with_dispatcher = f'{dispatcher.path_entry}:{sandbox_path_dir}'

    hook_run = _run_hook(
        'terraform_wrapper_module_for_each.sh',
        [],
        cwd=tmp_repo,
        env=_hook_env(_pct_cache_env(cache_dir), path_with_dispatcher),
    )

    combined = hook_run.stdout
    assert UNTAGGED_MSG in combined, combined
    assert AUTOUPDATE_MSG in combined, combined

    cache_file = cache_dir / '.last_update_check'
    assert cache_file.exists()


@pytest.mark.network
def test_real_network_sanity_check(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Sanity test hitting the real hardcoded URL.

    Asserts only that the call succeeds and returns parseable
    `sha<TAB>refs/tags/...` lines - no assertion on a specific version number.
    """
    # Create terraform stub for this test
    # Need dispatcher for stub creation even though not used for network
    dispatcher = _GitDispatcherStub(tmp_path)
    _create_terraform_stub(dispatcher)

    # Use real PATH (no dispatcher) to hit real network, but include stub dir
    path_with_stub = f'{dispatcher.path_entry}:{os.environ["PATH"]}'
    hook_run = _run_hook(
        'terraform_fmt.sh',
        [],
        cwd=tmp_repo,
        env=_hook_env(_pct_cache_env(cache_dir), path_with_stub),
    )

    combined = hook_run.stdout

    # Either the check succeeds (and we might see a nag if outdated/untagged)
    # or it fails with timeout/network error (and we see failure message)
    # or it's skipped due to fresh cache (first run creates cache)

    # Cache file should exist (attempt was made)
    cache_file = cache_dir / '.last_update_check'
    assert cache_file.exists()

    # Hook should complete successfully regardless
    assert hook_run.returncode == 0, combined
