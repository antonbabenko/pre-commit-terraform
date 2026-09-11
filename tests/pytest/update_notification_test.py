"""Black-box tests for the update notification feature.

Tests the `_check_new_version_on_failure` function in
`hooks/_check_new_version_on_failure.sh`. Every test invokes a real hook
script as a subprocess and asserts on its
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
# Generous upper bound (vs. the ~3s the watchdog itself targets): catches
# a broken watchdog without flaking on a loaded CI box, while still being
# far short of the hung call's real 60s / the 30s subprocess timeout
# either would hit if the watchdog never fired at all.
_WATCHDOG_BOUND_SECONDS = 10
# Grace period for the OS to finish reaping a just-killed process
# before a liveness check (`os.kill(pid, 0)`) is expected to be honest.
_PROCESS_REAP_GRACE_SECONDS = 0.2

# Diagnostic messages emitted via `common::colorify` calls in
# `hooks/_check_new_version_on_failure.sh`.
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
SKIP_SUGGESTION_MSG = (
    'Set CI=true or PCT_SKIP_UPDATE_CHECK=true to never check for updates.'
)

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
    """A `git` dispatcher stub forwarding all commands except two.

    When placed ahead of the real `git` on `$PATH`, this stub intercepts
    `git ls-remote` and the hook's own `git -C <hooks_dir> rev-parse HEAD`
    lookup, returning canned fixture data for both, while forwarding all
    other subcommands (`rev-parse HEAD` without `-C`, `ls-files`, etc.) to
    the real `git`. This keeps the hook's genuine git usage real while
    making both the remote tag query and the hook's own pinned-sha lookup
    fully deterministic and network-free.
    """

    def __init__(self, tmp_path: Path) -> None:  # pragma: win32 no cover
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
            '  if [[ -f "${0}.ls-remote-hang" ]]; then\n'
            '    # Forked child, mimicking the real remote-helper process\n'
            '    sleep 60 &\n'
            '    echo "$!" > "${0}.ls-remote-hang-child-pid"\n'
            '    wait\n'
            '  fi\n'
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
            'elif [[ "$1" == "-C" && "$3" == "rev-parse" && "$4" == "HEAD" ]]; then\n'  # noqa: E501
            '  # Intercept the hook checkout HEAD lookup\n'
            '  if [[ -f "${0}.current-sha" ]]; then\n'
            '    cat "${0}.current-sha"\n'
            '  else\n'
            '    exec "$(dirname "$0")/real-git" "$@"\n'
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

    def set_ls_remote_output(  # pragma: win32 no cover
        self,
        output: str,
        exit_code: int = 0,
    ) -> None:
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

    def set_ls_remote_hang(self) -> None:  # pragma: win32 no cover
        """Make the canned `ls-remote` call hang instead of returning.

        Used to prove the watchdog actually bounds a stalled query,
        rather than a canned instant exit code that never exercises it.
        The stub forks a child for the hang (see `hung_helper_pid`),
        mimicking `git`'s own separate remote-helper process.
        """
        stub_dir, stub_name = self.stub_path.parent, self.stub_path.name
        (stub_dir / f'{stub_name}.ls-remote-hang').touch()

    def hung_helper_pid(self) -> int:  # pragma: win32 no cover
        """Read back the remote-helper child PID a hung call recorded.

        Only valid after `set_ls_remote_hang()` and an actual hung
        invocation - raises `FileNotFoundError` otherwise.

        Returns:
            The child's PID.
        """
        stub_dir, stub_name = self.stub_path.parent, self.stub_path.name
        pid_file = stub_dir / f'{stub_name}.ls-remote-hang-child-pid'
        return int(pid_file.read_text(encoding='utf-8').strip())

    def set_current_sha(self, sha: str) -> None:  # pragma: win32 no cover
        """Configure the canned sha for the hook checkout's own `HEAD`.

        Args:
            sha: The sha the hook should resolve its own pinned `rev` to.
        """
        stub_dir, stub_name = self.stub_path.parent, self.stub_path.name
        (stub_dir / f'{stub_name}.current-sha').write_text(
            sha,
            encoding='utf-8',
        )

    @property
    def path_entry(self) -> str:  # pragma: win32 no cover
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


def _create_terraform_stub(  # pragma: win32 no cover
    dispatcher: _GitDispatcherStub,
) -> None:
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
        'pgrep',
        'rm',
        'sed',
        'sleep',
        'sort',
        'tail',
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
        # Not on stock macOS (needs GNU coreutils) - the hook itself
        # already tolerates its absence (`command -v timeout` guard),
        # so the sandbox must too, not hard-require it.
        'timeout',
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


def _read_cache_timestamp(  # pragma: win32 no cover
    time_cache_file: Path,
) -> int:
    """Read the cached timestamp from `.last_update_check_time`.

    Returns:
        The cached timestamp as an int.
    """
    return int(time_cache_file.read_text(encoding='utf-8').strip())


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
    """Check `$CI` set → no network attempt, cache file untouched.

    The check only runs at all once the hook itself is about to exit
    non-zero (`trap ... EXIT` in `hooks/_common.sh`), so no terraform
    stub is installed here - the hook fails on its own (missing
    terraform/tofu), which is what arms the check in the first place;
    `$CI` must then still suppress it from there.
    """
    dispatcher = _GitDispatcherStub(tmp_path)
    dispatcher.set_ls_remote_output(SAMPLE_LS_REMOTE_OUTPUT)

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

    # Cache files should not exist (check was skipped without attempt)
    time_cache_file = cache_dir / '.last_update_check_time'
    tags_cache_file = cache_dir / '.last_update_check_tags'
    assert not time_cache_file.exists(), (
        f'Cache file missing check: {time_cache_file}'
    )
    assert not tags_cache_file.exists(), (
        f'Cache file missing check: {tags_cache_file}'
    )

    # Hook fails on its own (no terraform/tofu) - that failure is what
    # arms the trap; $CI must suppress the check regardless.
    assert hook_run.returncode != 0, combined


def test_pct_skip_update_check_set_skips_check(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check `$PCT_SKIP_UPDATE_CHECK` set → no attempt, cache untouched.

    No terraform stub: the hook must fail on its own to arm the trap in
    the first place, and `$PCT_SKIP_UPDATE_CHECK` must then still
    suppress the check from there.
    """
    dispatcher = _GitDispatcherStub(tmp_path)
    dispatcher.set_ls_remote_output(SAMPLE_LS_REMOTE_OUTPUT)

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

    time_cache_file = cache_dir / '.last_update_check_time'
    tags_cache_file = cache_dir / '.last_update_check_tags'
    assert not time_cache_file.exists(), (
        f'Cache file missing check: {time_cache_file}'
    )
    assert not tags_cache_file.exists(), (
        f'Cache file missing check: {tags_cache_file}'
    )
    assert hook_run.returncode != 0, combined


def test_corrupted_timestamp_treated_as_stale(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check a malformed cached timestamp is treated as absent, not fatal.

    No file locking (see design.md) means a torn/partial write can
    leave `.last_update_check_time` holding garbage instead of a plain
    integer. Feeding that straight into bash arithmetic either
    silently becomes 0 or raises an expression error depending on
    exactly what landed there - neither of which this cache should
    ever trust. A real attempt must still happen (and correct the
    cache going forward), not silently break the check forever.
    """
    dispatcher = _GitDispatcherStub(tmp_path)
    dispatcher.set_ls_remote_output(SAMPLE_LS_REMOTE_OUTPUT)

    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    path_with_dispatcher = f'{dispatcher.path_entry}:{sandbox_path_dir}'

    time_cache_file = cache_dir / '.last_update_check_time'
    time_cache_file.parent.mkdir(parents=True, exist_ok=True)
    time_cache_file.write_text('12345corrupted', encoding='utf-8')

    hook_run = _run_hook(
        'terraform_fmt.sh',
        [],
        cwd=tmp_repo,
        env=_hook_env(_pct_cache_env(cache_dir), path_with_dispatcher),
    )

    combined = hook_run.stdout
    assert UNTAGGED_MSG in combined, combined
    assert AUTOUPDATE_MSG in combined, combined

    # The real attempt corrects the cache going forward - a clean,
    # current timestamp, not the garbage that was there before.
    new_timestamp = _read_cache_timestamp(time_cache_file)
    assert new_timestamp > int(time.time()) - _SECONDS_PER_HOUR
    assert hook_run.returncode != 0, combined


def test_future_timestamp_treated_as_stale(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check a bogus future-dated timestamp is treated as stale, not fresh.

    A well-formed but future timestamp (clock skew, or the same kind
    of corruption as a malformed one) would otherwise compute a
    negative age - satisfying `age < 7 days` and getting treated as
    "fresh" forever, permanently suppressing real checks.
    """
    dispatcher = _GitDispatcherStub(tmp_path)
    dispatcher.set_ls_remote_output(SAMPLE_LS_REMOTE_OUTPUT)

    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    path_with_dispatcher = f'{dispatcher.path_entry}:{sandbox_path_dir}'

    time_cache_file = cache_dir / '.last_update_check_time'
    time_cache_file.parent.mkdir(parents=True, exist_ok=True)
    future_time = int(time.time()) + _SECONDS_PER_DAY
    time_cache_file.write_text(str(future_time), encoding='utf-8')

    hook_run = _run_hook(
        'terraform_fmt.sh',
        [],
        cwd=tmp_repo,
        env=_hook_env(_pct_cache_env(cache_dir), path_with_dispatcher),
    )

    combined = hook_run.stdout
    assert UNTAGGED_MSG in combined, combined
    assert AUTOUPDATE_MSG in combined, combined

    new_timestamp = _read_cache_timestamp(time_cache_file)
    assert new_timestamp <= int(time.time())
    assert hook_run.returncode != 0, combined


def test_stale_cache_outdated_tag_nag(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check stale cache + pinned tag older than latest → nag printed.

    No terraform stub: the check only runs once the hook is about to
    exit non-zero, so the hook is left to fail on its own.
    """
    dispatcher = _GitDispatcherStub(tmp_path)
    dispatcher.set_ls_remote_output(SAMPLE_LS_REMOTE_OUTPUT)
    # Pin the hook's own checkout to the v1.3.0 fixture sha already in
    # `SAMPLE_LS_REMOTE_OUTPUT` above - not a tag/commit on `tmp_repo`,
    # which is the *linted project*, never the hook's own checkout.
    dispatcher.set_current_sha('dddddddddddddddddddddddddddddddddddddddd')

    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    path_with_dispatcher = f'{dispatcher.path_entry}:{sandbox_path_dir}'

    # Create a stale cache file (8 days old)
    time_cache_file = cache_dir / '.last_update_check_time'
    time_cache_file.parent.mkdir(parents=True, exist_ok=True)
    eight_days_ago = int(time.time()) - (8 * _SECONDS_PER_DAY)
    time_cache_file.write_text(str(eight_days_ago), encoding='utf-8')

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
    new_timestamp = _read_cache_timestamp(time_cache_file)
    assert new_timestamp > eight_days_ago
    assert hook_run.returncode != 0, combined


def test_stale_cache_untagged_nag(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check stale/absent cache + HEAD matches no tag → nag printed.

    No terraform stub: the hook fails on its own, which is what arms
    the check in the first place.
    """
    dispatcher = _GitDispatcherStub(tmp_path)
    dispatcher.set_ls_remote_output(SAMPLE_LS_REMOTE_OUTPUT)

    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    path_with_dispatcher = f'{dispatcher.path_entry}:{sandbox_path_dir}'

    # Create a stale cache file (8 days old)
    time_cache_file = cache_dir / '.last_update_check_time'
    time_cache_file.parent.mkdir(parents=True, exist_ok=True)
    eight_days_ago = int(time.time()) - (8 * _SECONDS_PER_DAY)
    time_cache_file.write_text(str(eight_days_ago), encoding='utf-8')

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
    new_timestamp = _read_cache_timestamp(time_cache_file)
    assert new_timestamp > eight_days_ago
    assert hook_run.returncode != 0, combined


def test_stale_cache_up_to_date_silent(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check stale/absent cache + pinned tag equals latest → no output.

    No terraform stub: the hook still fails (for its own, unrelated
    reason), which is exactly the point - even on a failing hook, an
    already-up-to-date pin must stay silent.
    """
    dispatcher = _GitDispatcherStub(tmp_path)
    dispatcher.set_ls_remote_output(SAMPLE_LS_REMOTE_OUTPUT)
    # Pin the hook's own checkout to the v1.4.0 fixture sha (latest) -
    # not a tag on `tmp_repo`, which is only the linted project.
    dispatcher.set_current_sha('eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee')

    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    path_with_dispatcher = f'{dispatcher.path_entry}:{sandbox_path_dir}'

    # Create a stale cache file (8 days old)
    time_cache_file = cache_dir / '.last_update_check_time'
    time_cache_file.parent.mkdir(parents=True, exist_ok=True)
    eight_days_ago = int(time.time()) - (8 * _SECONDS_PER_DAY)
    time_cache_file.write_text(str(eight_days_ago), encoding='utf-8')

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
    new_timestamp = _read_cache_timestamp(time_cache_file)
    assert new_timestamp > eight_days_ago
    assert hook_run.returncode != 0, combined


def test_annotated_tag_matches_via_peeled_commit(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check an annotated tag's peeled commit OID is what gets matched.

    `git ls-remote --tags` (no `--refs`) returns *two* lines for an
    annotated tag: the tag *object* OID against the bare ref, and the
    real commit OID against that same ref suffixed `^{}`. A checkout
    pinned to the peeled/commit OID must be recognized as up-to-date -
    matching only the (different) tag-object OID would report every
    annotated-tag pin as a non-release commit, forever. Fixture values
    are the real, verified OID pair for antonbabenko/pre-commit-terraform's
    own `v1.50.0` tag (which is annotated upstream).
    """
    dispatcher = _GitDispatcherStub(tmp_path)
    tag_object_sha = 'd032af694c17201cfcbd4d5ac106dd37926d39f9'
    peeled_commit_sha = '9b84f70efef7419e53c9526dff2e4a7d6bc9c78d'
    dispatcher.set_ls_remote_output(
        f'{tag_object_sha}\trefs/tags/v1.50.0\n'
        f'{peeled_commit_sha}\trefs/tags/v1.50.0^{{}}\n',
    )
    dispatcher.set_current_sha(peeled_commit_sha)

    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    path_with_dispatcher = f'{dispatcher.path_entry}:{sandbox_path_dir}'

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
    assert hook_run.returncode != 0, combined


def test_network_failure_warning(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check dispatcher stub makes `ls-remote` fail → warn notice printed.

    No terraform stub: the hook fails on its own, arming the check,
    which then separately fails again over the (simulated) network.
    """
    dispatcher = _GitDispatcherStub(tmp_path)
    dispatcher.set_ls_remote_output('', exit_code=1)  # Non-zero exit

    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    path_with_dispatcher = f'{dispatcher.path_entry}:{sandbox_path_dir}'

    # Create a stale cache file
    time_cache_file = cache_dir / '.last_update_check_time'
    time_cache_file.parent.mkdir(parents=True, exist_ok=True)
    eight_days_ago = int(time.time()) - (8 * _SECONDS_PER_DAY)
    time_cache_file.write_text(str(eight_days_ago), encoding='utf-8')

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
    new_timestamp = _read_cache_timestamp(time_cache_file)
    assert new_timestamp > eight_days_ago
    # The hook's own (unrelated) failure is what armed the check;
    # nothing about the check itself adds to or changes that exit code.
    assert hook_run.returncode != 0, combined


def test_network_failure_preserves_cached_latest(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check a failed remote query keeps the previously cached tags.

    Only the timestamp (line 1) advances; the previously cached tag
    lines must survive a failed attempt untouched, so the fast path
    can keep using them once the cache goes fresh again.
    """
    dispatcher = _GitDispatcherStub(tmp_path)
    dispatcher.set_ls_remote_output('', exit_code=1)

    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    path_with_dispatcher = f'{dispatcher.path_entry}:{sandbox_path_dir}'

    time_cache_file = cache_dir / '.last_update_check_time'
    tags_cache_file = cache_dir / '.last_update_check_tags'
    time_cache_file.parent.mkdir(parents=True, exist_ok=True)
    eight_days_ago = int(time.time()) - (8 * _SECONDS_PER_DAY)
    previously_cached_tags = (
        'cccccccccccccccccccccccccccccccccccccccc\trefs/tags/v1.2.0\n'
    )
    time_cache_file.write_text(str(eight_days_ago), encoding='utf-8')
    tags_cache_file.write_text(previously_cached_tags, encoding='utf-8')

    hook_run = _run_hook(
        'terraform_fmt.sh',
        [],
        cwd=tmp_repo,
        env=_hook_env(_pct_cache_env(cache_dir), path_with_dispatcher),
    )

    assert FAILED_MSG in hook_run.stdout, hook_run.stdout
    assert _read_cache_timestamp(time_cache_file) > eight_days_ago
    assert (
        tags_cache_file.read_text(encoding='utf-8') == previously_cached_tags
    )


def test_second_failure_skips_network_without_tags(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check back-to-back failures honor the throttle without any tags.

    A first failing attempt (network down) writes only the timestamp -
    no tag cache exists yet, since one is only ever written on success.
    A second failing run minutes later must still skip the network
    entirely: the 7-day throttle is gated on the timestamp alone, not
    on whether a tag cache happens to already exist.
    """
    dispatcher = _GitDispatcherStub(tmp_path)
    dispatcher.set_ls_remote_output('', exit_code=1)

    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    path_with_dispatcher = f'{dispatcher.path_entry}:{sandbox_path_dir}'
    env = _hook_env(_pct_cache_env(cache_dir), path_with_dispatcher)

    first_run = _run_hook('terraform_fmt.sh', [], cwd=tmp_repo, env=env)
    assert FAILED_MSG in first_run.stdout, first_run.stdout

    time_cache_file = cache_dir / '.last_update_check_time'
    tags_cache_file = cache_dir / '.last_update_check_tags'
    assert time_cache_file.exists()
    assert not tags_cache_file.exists()
    first_timestamp = _read_cache_timestamp(time_cache_file)

    # Detectably-different data: if the second run queries the network
    # at all, this would show up in its output, proving the throttle
    # was bypassed instead of actually skipping the attempt.
    dispatcher.set_ls_remote_output(
        'ffffffffffffffffffffffffffffffffffffffff\trefs/tags/v9.9.9\n',
    )

    second_run = _run_hook('terraform_fmt.sh', [], cwd=tmp_repo, env=env)
    combined = second_run.stdout
    assert FAILED_MSG not in combined, combined
    assert UNTAGGED_MSG not in combined, combined
    assert 'v9.9.9' not in combined, combined
    assert not tags_cache_file.exists()
    # No real attempt was made this time, so the timestamp is untouched.
    assert _read_cache_timestamp(time_cache_file) == first_timestamp


def test_network_query_bounded_by_watchdog(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check a hung `ls-remote` gets killed by the watchdog within ~3s.

    Proves the portable watchdog (no `timeout` dependency) actually
    bounds a stalled query, rather than merely asserting the exit-code
    branch it *would* take on a real timeout - a canned instant exit
    code would never exercise the watchdog at all, exactly the gap that
    let a missing `sleep` on the sandboxed `PATH` silently disable it.
    """
    dispatcher = _GitDispatcherStub(tmp_path)
    dispatcher.set_ls_remote_hang()

    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    path_with_dispatcher = f'{dispatcher.path_entry}:{sandbox_path_dir}'

    start = time.monotonic()
    hook_run = _run_hook(
        'terraform_fmt.sh',
        [],
        cwd=tmp_repo,
        env=_hook_env(_pct_cache_env(cache_dir), path_with_dispatcher),
    )
    elapsed = time.monotonic() - start

    combined = hook_run.stdout
    assert TIMEOUT_MSG in combined, combined
    assert SKIP_SUGGESTION_MSG in combined, combined
    assert elapsed < _WATCHDOG_BOUND_SECONDS, (
        f'took {elapsed:.1f}s, watchdog should bound to ~3s'
    )
    assert hook_run.returncode != 0, combined


def test_watchdog_kills_remote_helper_child_too(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check the watchdog kills git's remote-helper child, not just git.

    `git ls-remote https://...` spawns a separate remote-helper process
    (`git remote-https`, confirmed against a real invocation) to do the
    actual network I/O. Killing only the parent PID lets that helper
    survive and keep running after the hook returns - the dispatcher
    stub forks its own child on a hang to mimic this exact shape.
    """
    dispatcher = _GitDispatcherStub(tmp_path)
    dispatcher.set_ls_remote_hang()

    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    path_with_dispatcher = f'{dispatcher.path_entry}:{sandbox_path_dir}'

    hook_run = _run_hook(
        'terraform_fmt.sh',
        [],
        cwd=tmp_repo,
        env=_hook_env(_pct_cache_env(cache_dir), path_with_dispatcher),
    )

    assert TIMEOUT_MSG in hook_run.stdout, hook_run.stdout

    helper_pid = dispatcher.hung_helper_pid()
    time.sleep(_PROCESS_REAP_GRACE_SECONDS)
    with pytest.raises(ProcessLookupError):
        os.kill(helper_pid, 0)


def test_fresh_cache_still_nags_when_outdated(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check a fresh cache still nags every failing run if still outdated.

    Rate-limiting only throttles the *network query*, not the nag
    itself: the dispatcher's configured `ls-remote` output claims
    v9.9.9 is latest, but since the cache is fresh that must never be
    queried - if this test observes "v9.9.9" anywhere, the fast path
    incorrectly hit the network instead of using the cached v1.2.0.
    """
    dispatcher = _GitDispatcherStub(tmp_path)
    dispatcher.set_ls_remote_output(
        'ffffffffffffffffffffffffffffffffffffffff\trefs/tags/v9.9.9\n',
    )

    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    path_with_dispatcher = f'{dispatcher.path_entry}:{sandbox_path_dir}'

    time_cache_file = cache_dir / '.last_update_check_time'
    tags_cache_file = cache_dir / '.last_update_check_tags'
    time_cache_file.parent.mkdir(parents=True, exist_ok=True)
    one_hour_ago = int(time.time()) - _SECONDS_PER_HOUR
    stale_sha = 'cccccccccccccccccccccccccccccccccccccccc'
    stale_tags_line = f'{stale_sha}\trefs/tags/v1.2.0\n'
    time_cache_file.write_text(str(one_hour_ago), encoding='utf-8')
    tags_cache_file.write_text(stale_tags_line, encoding='utf-8')

    hook_run = _run_hook(
        'terraform_fmt.sh',
        [],
        cwd=tmp_repo,
        env=_hook_env(_pct_cache_env(cache_dir), path_with_dispatcher),
    )

    combined = hook_run.stdout
    assert UNTAGGED_MSG in combined, combined
    assert 'v1.2.0' in combined, combined
    assert 'v9.9.9' not in combined, combined

    # Fast path never touches either cache file.
    assert time_cache_file.read_text(encoding='utf-8') == str(one_hour_ago)
    assert tags_cache_file.read_text(encoding='utf-8') == stale_tags_line
    assert hook_run.returncode != 0, combined


def test_fresh_cache_stays_silent_when_matching(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check a fresh cache stays silent when HEAD matches cached latest."""
    dispatcher = _GitDispatcherStub(tmp_path)
    dispatcher.set_ls_remote_output(
        'ffffffffffffffffffffffffffffffffffffffff\trefs/tags/v9.9.9\n',
    )
    # Pin the hook's own checkout to the same sha cached below as
    # latest - not a tag on `tmp_repo`, the linted project.
    current_sha = 'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee'
    dispatcher.set_current_sha(current_sha)

    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    path_with_dispatcher = f'{dispatcher.path_entry}:{sandbox_path_dir}'

    time_cache_file = cache_dir / '.last_update_check_time'
    tags_cache_file = cache_dir / '.last_update_check_tags'
    time_cache_file.parent.mkdir(parents=True, exist_ok=True)
    one_hour_ago = int(time.time()) - _SECONDS_PER_HOUR
    time_cache_file.write_text(str(one_hour_ago), encoding='utf-8')
    tags_cache_file.write_text(
        f'{current_sha}\trefs/tags/v1.4.0\n',
        encoding='utf-8',
    )

    hook_run = _run_hook(
        'terraform_fmt.sh',
        [],
        cwd=tmp_repo,
        env=_hook_env(_pct_cache_env(cache_dir), path_with_dispatcher),
    )

    combined = hook_run.stdout
    assert OUTDATED_MSG not in combined, combined
    assert UNTAGGED_MSG not in combined, combined
    assert 'v9.9.9' not in combined, combined
    assert hook_run.returncode != 0, combined


def test_check_at_most_once_per_invocation(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check hook invoked across multiple dirs attempts check at most once.

    No terraform stub: the hook fails on its own, which is what arms
    the `trap ... EXIT` in `hooks/_common.sh` exactly once for the
    whole invocation - not once per per-dir subshell.
    """
    dispatcher = _GitDispatcherStub(tmp_path)
    dispatcher.set_ls_remote_output(SAMPLE_LS_REMOTE_OUTPUT)

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

    # Cache files should exist (check was attempted)
    assert (cache_dir / '.last_update_check_time').exists()
    assert (cache_dir / '.last_update_check_tags').exists()
    assert multi_dir_run.returncode != 0, combined


def test_check_fires_without_per_dir_hook(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check the notice fires for a hook that never calls `per_dir_hook`.

    `terraform_wrapper_module_for_each.sh` has its own whole-repo flow and
    never calls `common::per_dir_hook` (see `hooks/_common.sh` -
    `_check_new_version_on_failure` must be wired up regardless, via
    `common::initialize`, not from inside
    `common::per_dir_hook`, or this exact hook silently loses
    coverage). The hook's own tool
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

    assert (cache_dir / '.last_update_check_time').exists()
    assert (cache_dir / '.last_update_check_tags').exists()


@pytest.mark.network
def test_real_network_sanity_check(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Sanity test hitting the real hardcoded URL.

    No dispatcher and no terraform stub, deliberately: a dispatcher
    would intercept `ls-remote` with its own canned/empty response
    (defeating the point of a *real*-network test) even if never
    explicitly configured via `set_ls_remote_output`, and a terraform
    stub would make the hook succeed - which would mean the check,
    gated on hook failure, never runs at all. `_sandbox_path_dir` alone
    already includes real `git` (hits real network) and no
    terraform/tofu (hook fails, arming the check).

    Asserts only that the call succeeds and returns parseable
    `sha<TAB>refs/tags/...` lines - no assertion on a specific version
    number, which changes over time.
    """
    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    hook_run = _run_hook(
        'terraform_fmt.sh',
        [],
        cwd=tmp_repo,
        env=_hook_env(_pct_cache_env(cache_dir), str(sandbox_path_dir)),
    )

    combined = hook_run.stdout

    # Either the check succeeds (and we might see a nag if outdated/untagged)
    # or it fails with timeout/network error (and we see failure message) -
    # the timestamp advances on any real attempt either way, but the tag
    # cache is only ever written on success (see design.md Decision 3), so
    # asserting it unconditionally would flake whenever GitHub is briefly
    # unreachable from CI.
    assert (cache_dir / '.last_update_check_time').exists()
    if (
        TIMEOUT_MSG not in combined and FAILED_MSG not in combined
    ):  # pragma: no cover
        tags_cache_file = cache_dir / '.last_update_check_tags'
        assert tags_cache_file.exists()
        # Parseable `sha<TAB>refs/tags/...` lines, per this test's own
        # docstring promise.
        tags_content = tags_cache_file.read_text(encoding='utf-8')
        assert '\trefs/tags/' in tags_content, tags_content

    # The hook fails on its own (no terraform/tofu) - that's what arms
    # the check; nothing about the check itself changes this exit code.
    assert hook_run.returncode != 0, combined


def test_hook_success_skips_check_even_when_outdated(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check a successful hook never runs the check, however outdated.

    Mirror image of every other stale-cache test above: same outdated
    fixture and stale cache, but this time WITH a terraform stub so the
    hook succeeds. `_check_new_version_on_failure` only
    does anything when the hook's own exit code is non-zero, so a
    successful hook must stay completely silent and leave the
    cache file untouched - regardless of how outdated the
    pin actually is.
    """
    dispatcher = _GitDispatcherStub(tmp_path)
    dispatcher.set_ls_remote_output(SAMPLE_LS_REMOTE_OUTPUT)
    _create_terraform_stub(dispatcher)

    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    path_with_dispatcher = f'{dispatcher.path_entry}:{sandbox_path_dir}'

    # Stale cache, so the only thing preventing an attempt is the
    # hook's own success.
    time_cache_file = cache_dir / '.last_update_check_time'
    tags_cache_file = cache_dir / '.last_update_check_tags'
    time_cache_file.parent.mkdir(parents=True, exist_ok=True)
    eight_days_ago = int(time.time()) - (8 * _SECONDS_PER_DAY)
    time_cache_file.write_text(str(eight_days_ago), encoding='utf-8')

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

    # Cache untouched: the check was never even attempted.
    assert time_cache_file.read_text(encoding='utf-8') == str(eight_days_ago)
    assert not tags_cache_file.exists()
    assert hook_run.returncode == 0, combined
