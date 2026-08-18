"""Black-box regression tests for `--hook-config=--tool-version=` resolution.

Every test here invokes a real hook script under `hooks/` as a subprocess
and asserts on its exit code, the cache directory's filesystem state, and
its output - never on a bash-internal function name - so these tests
require minimal changes if a hook is ever reimplemented in another
language.

Each network-free test proves *which* binary the hook actually executed by
pre-populating the cache (or `$PATH`) with a stub that echoes a unique
marker, then asserting that marker in the hook's output. Asserting only on
a log line or on a file the test itself created cannot distinguish a
resolved stub from an unrelated real tool that happens to be installed on
the machine running the suite.

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
from pathlib import Path
from typing import NamedTuple

import pytest


REPO_ROOT = Path(__file__).resolve().parents[2]
HOOKS_DIR = REPO_ROOT / 'hooks'

# Both are resolved against *this* process' `PATH` by `execvp`, not against
# the `PATH` handed to the subprocess - which is what keeps a sandboxed
# `PATH` (see `_sandbox_path_dir`) from breaking the interpreter itself
# while still hiding wrapped CLI tools from the hook under test.
GIT = shutil.which('git') or 'git'
BASH = shutil.which('bash') or 'bash'

# Diagnostic messages emitted by `common::colorify` in `hooks/_common.sh`.
# Named here so that a reworded message breaks in one place, and so that
# every assertion points at the implementation line it is coupled to.
# `common::colorify` writes to stderr, hence the stderr/stdout merge in
# `_run_hook` below.
DOWNLOAD_MSG = "Downloading '"  # hooks/_common.sh:662
STRICT_OVERRIDE_MSG = 'downloaded/used instead of whatever is on $PATH'  # :629
PREFER_LOCAL_MSG = "'--tool-version-mode=prefer-local'"  # :622
NO_INSTALLER_MSG = 'no installer found'  # :658
MODE_INVALID_MSG = "'--tool-version-mode=prefer_local' is not a valid value"
TOOL_MISSING_MSG = "is not discoverable in the system's PATH"  # :602
TF_PATH_INVALID_MSG = 'not a valid value'  # :739
PARALLELISM_CAPPED_MSG = 'Observed Parallelism limit'  # :409

PINNED_TFLINT_VERSION = '0.50.0'
PINNED_TF_VERSION = '1.9.0'
# Any tool, any version: used where the cache is seeded by the test and
# the exact number is irrelevant to what is being asserted.
PINNED_ANY_VERSION = '9.9.9'

HOOK_TIMEOUT_SECONDS = 300
VERSION_CHECK_TIMEOUT_SECONDS = 60


class _CachedTool(NamedTuple):
    """Cache entry a hook is expected to resolve a pinned tool to."""

    tool_dir: str
    bin_name: str

    def stub_path(self, cache_root: Path, version: str) -> Path:
        """Build the `<root>/<tool>/<version>/<binary>` cache path.

        Args:
            cache_root: Cache root the hook is pointed at.
            version: Pinned version under test.

        Returns:
            Path the hook must resolve the pinned tool to.
        """
        return cache_root / self.tool_dir / version / self.bin_name


class _HookWiring(NamedTuple):
    """A hook plus the cached tool its `tool_name` must resolve to."""

    hook_name: str
    cached_tool: _CachedTool
    extra_args: tuple[str, ...]


_SANDBOX_REQUIRED_TOOLS = (
    'awk',
    'basename',
    # The stubs written by `_write_stub` are `#!/usr/bin/env bash` scripts,
    # so `env` must be able to find `bash` on the sandboxed `PATH` too.
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
    'tr',
    'uname',
    'wc',
    'git',
)
_SANDBOX_OPTIONAL_TOOLS = (
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
# Probed in this order by `common::get_cpu_num` (hooks/_common.sh:235) to
# size parallelism. Each is absent on some platform this project supports,
# which is why they are optional above rather than required.
_CPU_COUNT_TOOLS = ('nproc', 'sysctl')

pytestmark = pytest.mark.skipif(
    sys.platform == 'win32',
    reason=(
        'Hook-subprocess tests are skipped on Windows: this repository '
        'does not fully support/guarantee Windows hook execution '
        '(see README.md / .github/CONTRIBUTING.md).'
    ),
)


def _write_stub(path: Path, marker: str) -> None:  # pragma: win32 no cover
    """Write a fake, executable binary that prints a marker and exits 0."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        f'#!/usr/bin/env bash\necho "{marker}"\nexit 0\n',
        encoding='utf-8',
    )
    exec_bits = stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH
    path.chmod(path.stat().st_mode | exec_bits)


def _sandbox_path_dir(base: Path) -> Path:  # pragma: win32 no cover
    """Build a `PATH` dir with coreutils but no wrapped CLI tool.

    None of the linked names collides with a tool any hook wraps
    (`tflint`, `terraform`, `tofu`, ...), so a hook run against this
    `PATH` can only resolve a wrapped tool through the cache - never
    through an incidental real install on the host.

    Returns:
        Path to the constructed directory, usable as a `PATH` entry.
    """
    path_dir = base / 'sandbox-path'
    path_dir.mkdir()
    for tool in _SANDBOX_REQUIRED_TOOLS:
        found = shutil.which(tool)
        assert found is not None, f'{tool!r} not found on PATH'
        (path_dir / tool).symlink_to(found)
    for optional_tool in _SANDBOX_OPTIONAL_TOOLS:
        optional_found = shutil.which(optional_tool)
        # `no branch`: whether the False arc is ever taken depends on the
        # host's `PATH`, not on anything a test controls - every CI runner
        # resolves all of these, while e.g. a Linux box that keeps
        # `/usr/sbin` off `PATH` resolves no `sysctl`. These are optional
        # precisely because the hooks treat them as optional too, see
        # `hooks/_common.sh:300`: `nproc || sysctl -n hw.ncpu || echo 1`.
        if optional_found is not None:  # pragma: no branch
            (path_dir / optional_tool).symlink_to(optional_found)
    return path_dir


def _hook_env(  # pragma: win32 no cover
    cache_env: dict[str, str],
    path: str,
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

    Returns:
        The environment mapping to hand to `subprocess.run`.
    """
    return {
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
        **cache_env,
    }


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
        # `hooks/` is not part of the wheel, only of the sdist, so a
        # packaging regression must fail with a pointed message here
        # instead of as a confusing assertion mismatch further down.
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


def test_cache_hit_uses_cached_binary(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check a pre-populated cache entry is executed, with no download."""
    stub = cache_dir / 'tflint' / PINNED_TFLINT_VERSION / 'tflint'
    _write_stub(stub, 'CACHED_TFLINT')

    hook_run = _run_hook(
        'terraform_tflint.sh',
        [f'--hook-config=--tool-version={PINNED_TFLINT_VERSION}'],
        cwd=tmp_repo,
        env=_hook_env(
            _pct_cache_env(cache_dir),
            str(_sandbox_path_dir(tmp_path)),
        ),
    )

    combined = hook_run.stdout
    assert 'CACHED_TFLINT' in combined, combined
    assert DOWNLOAD_MSG not in combined, combined
    assert hook_run.returncode == 0, combined


def test_strict_mode_prefers_pinned_over_path(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check that `strict` (default) mode executes the pinned version."""
    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    _write_stub(sandbox_path_dir / 'tflint', 'LOCAL_TFLINT')

    pinned = cache_dir / 'tflint' / PINNED_TFLINT_VERSION / 'tflint'
    _write_stub(pinned, 'PINNED_TFLINT')

    hook_run = _run_hook(
        'terraform_tflint.sh',
        [f'--hook-config=--tool-version={PINNED_TFLINT_VERSION}'],
        cwd=tmp_repo,
        env=_hook_env(_pct_cache_env(cache_dir), str(sandbox_path_dir)),
    )

    combined = hook_run.stdout
    assert 'PINNED_TFLINT' in combined, combined
    assert 'LOCAL_TFLINT' not in combined, combined
    assert STRICT_OVERRIDE_MSG in combined, combined
    assert hook_run.returncode == 0, combined


def test_prefer_local_mode_uses_path_binary(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check `prefer-local` mode executes the `$PATH` binary instead."""
    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    _write_stub(sandbox_path_dir / 'tflint', 'LOCAL_TFLINT')

    pinned = cache_dir / 'tflint' / PINNED_TFLINT_VERSION / 'tflint'
    _write_stub(pinned, 'PINNED_TFLINT')

    hook_run = _run_hook(
        'terraform_tflint.sh',
        [
            f'--hook-config=--tool-version={PINNED_TFLINT_VERSION}',
            '--hook-config=--tool-version-mode=prefer-local',
        ],
        cwd=tmp_repo,
        env=_hook_env(_pct_cache_env(cache_dir), str(sandbox_path_dir)),
    )

    combined = hook_run.stdout
    assert 'LOCAL_TFLINT' in combined, combined
    assert 'PINNED_TFLINT' not in combined, combined
    assert PREFER_LOCAL_MSG in combined, combined
    assert DOWNLOAD_MSG not in combined, combined
    assert hook_run.returncode == 0, combined


@pytest.mark.parametrize(
    ('hook_name', 'cached_tool'),
    (
        pytest.param(
            'terraform_tflint.sh',
            _CachedTool('tflint', 'tflint'),
            id='tflint',
        ),
        pytest.param(
            'terragrunt_fmt.sh',
            _CachedTool('terragrunt', 'terragrunt'),
            id='terragrunt-fmt',
        ),
    ),
)
def test_tool_is_resolved_only_once(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
    hook_name: str,
    cached_tool: _CachedTool,
) -> None:
    """Check a hook resolves its pinned tool exactly once per invocation.

    Hooks that need the resolved path for a pre-flight command (`tflint
    --init`, terragrunt's CLI-syntax version probe) used to resolve once
    for that and again inside `common::per_dir_hook`, logging the NOTE
    twice and entering the download path twice on a cache miss.

    Args:
        tmp_repo: Temp git repo fixture.
        cache_dir: Temp cache root fixture.
        tmp_path: Temp dir fixture, used for the sandboxed `PATH`.
        hook_name: Hook script filename under `hooks/`.
        cached_tool: Cache entry the hook is expected to resolve to.
    """
    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    _write_stub(sandbox_path_dir / cached_tool.bin_name, 'LOCAL_TOOL')
    _write_stub(
        cached_tool.stub_path(cache_dir, PINNED_ANY_VERSION),
        'PINNED_TOOL',
    )

    hook_run = _run_hook(
        hook_name,
        [f'--hook-config=--tool-version={PINNED_ANY_VERSION}'],
        cwd=tmp_repo,
        env=_hook_env(_pct_cache_env(cache_dir), str(sandbox_path_dir)),
    )

    combined = hook_run.stdout
    assert combined.count(STRICT_OVERRIDE_MSG) == 1, combined
    assert DOWNLOAD_MSG not in combined, combined


def test_rejects_invalid_tool_version_mode(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check an unrecognized `--tool-version-mode` is rejected, not ignored.

    Any value other than `strict`/`prefer-local` used to be treated as
    `strict`, so a typo such as `prefer_local` silently did the opposite
    of what was asked for.
    """
    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    _write_stub(sandbox_path_dir / 'tflint', 'LOCAL_TFLINT')
    pinned = cache_dir / 'tflint' / PINNED_TFLINT_VERSION / 'tflint'
    _write_stub(pinned, 'PINNED_TFLINT')

    hook_run = _run_hook(
        'terraform_tflint.sh',
        [
            f'--hook-config=--tool-version={PINNED_TFLINT_VERSION}',
            '--hook-config=--tool-version-mode=prefer_local',
        ],
        cwd=tmp_repo,
        env=_hook_env(_pct_cache_env(cache_dir), str(sandbox_path_dir)),
    )

    combined = hook_run.stdout
    assert hook_run.returncode != 0, combined
    assert MODE_INVALID_MSG in combined, combined
    assert 'LOCAL_TFLINT' not in combined, combined
    assert 'PINNED_TFLINT' not in combined, combined
    assert DOWNLOAD_MSG not in combined, combined


@pytest.mark.parametrize(
    ('tf_path_value', 'cached_tool'),
    (
        pytest.param(
            'terraform',
            _CachedTool('terraform', 'terraform'),
            id='terraform',
        ),
        pytest.param(
            'opentofu',
            _CachedTool('opentofu', 'tofu'),
            id='opentofu',
        ),
        pytest.param(
            'tofu',
            _CachedTool('opentofu', 'tofu'),
            id='tofu-alias',
        ),
    ),
)
def test_tf_path_selector(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
    tf_path_value: str,
    cached_tool: _CachedTool,
) -> None:
    """Check that `--tf-path=terraform|opentofu|tofu` selects the tool.

    Args:
        tmp_repo: Temp git repo fixture.
        cache_dir: Temp cache root fixture.
        tmp_path: Temp dir fixture, used for the sandboxed `PATH`.
        tf_path_value: The `--tf-path` value under test.
        cached_tool: Cache entry the hook is expected to resolve to.
    """
    _write_stub(
        cached_tool.stub_path(cache_dir, PINNED_TF_VERSION),
        'SELECTED_TF',
    )

    hook_run = _run_hook(
        'terraform_fmt.sh',
        [
            f'--hook-config=--tf-path={tf_path_value}',
            f'--hook-config=--tool-version={PINNED_TF_VERSION}',
        ],
        cwd=tmp_repo,
        env=_hook_env(
            _pct_cache_env(cache_dir),
            str(_sandbox_path_dir(tmp_path)),
        ),
    )

    combined = hook_run.stdout
    assert 'SELECTED_TF' in combined, combined
    assert DOWNLOAD_MSG not in combined, combined
    assert hook_run.returncode == 0, combined


@pytest.mark.parametrize(
    ('path_bin_names', 'cached_tool'),
    (
        pytest.param(
            ('terraform',),
            _CachedTool('terraform', 'terraform'),
            id='only-terraform-on-path',
        ),
        pytest.param(
            ('tofu',),
            _CachedTool('opentofu', 'tofu'),
            id='only-tofu-on-path',
        ),
        pytest.param(
            ('terraform', 'tofu'),
            _CachedTool('terraform', 'terraform'),
            id='both-on-path-terraform-wins',
        ),
    ),
)
def test_tf_path_autodetect(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
    path_bin_names: tuple[str, ...],
    cached_tool: _CachedTool,
) -> None:
    """Check `--tool-version` with `--tf-path` unset auto-detects the tool.

    This is the documented default (README's `--tf-path`/`--tool-version`
    matrix): Terraform wins whenever it is on `$PATH` - including when
    `tofu` is there too - and OpenTofu is picked only when `terraform` is
    absent while `tofu` is present.

    Args:
        tmp_repo: Temp git repo fixture.
        cache_dir: Temp cache root fixture.
        tmp_path: Temp dir fixture, used for the sandboxed `PATH`.
        path_bin_names: Terraform-ish binaries to put on `$PATH`.
        cached_tool: Cache entry the hook is expected to resolve to.
    """
    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    for path_bin_name in path_bin_names:
        _write_stub(sandbox_path_dir / path_bin_name, 'ON_PATH_TF')

    _write_stub(
        cached_tool.stub_path(cache_dir, PINNED_TF_VERSION),
        'AUTODETECTED_TF',
    )

    hook_run = _run_hook(
        'terraform_fmt.sh',
        [f'--hook-config=--tool-version={PINNED_TF_VERSION}'],
        cwd=tmp_repo,
        env=_hook_env(_pct_cache_env(cache_dir), str(sandbox_path_dir)),
    )

    combined = hook_run.stdout
    assert 'AUTODETECTED_TF' in combined, combined
    assert 'ON_PATH_TF' not in combined, combined
    assert DOWNLOAD_MSG not in combined, combined
    assert hook_run.returncode == 0, combined


def test_tf_path_passthrough_without_tool_version(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check `--tf-path` alone still passes a literal path through as-is.

    Guards the pre-`--tool-version` `--tf-path` contract: without a pinned
    version, an arbitrary path/binary name must be used verbatim and no
    cache entry may be created.
    """
    custom_binary = tmp_path / 'custom' / 'my-terraform'
    _write_stub(custom_binary, 'CUSTOM_TF')

    hook_run = _run_hook(
        'terraform_fmt.sh',
        [f'--hook-config=--tf-path={custom_binary}'],
        cwd=tmp_repo,
        env=_hook_env(
            _pct_cache_env(cache_dir),
            str(_sandbox_path_dir(tmp_path)),
        ),
    )

    combined = hook_run.stdout
    assert 'CUSTOM_TF' in combined, combined
    assert DOWNLOAD_MSG not in combined, combined
    assert not list(cache_dir.iterdir()), combined
    assert hook_run.returncode == 0, combined


@pytest.mark.parametrize(
    'cache_root_var',
    (
        pytest.param('XDG_CACHE_HOME', id='xdg-cache-home'),
        pytest.param('HOME', id='home-dot-cache'),
    ),
)
def test_cache_root_fallbacks(  # pragma: win32 no cover
    tmp_repo: Path,
    tmp_path: Path,
    cache_root_var: str,
) -> None:
    """Check the cache root falls back when `PCT_TOOL_CACHE_DIR` is unset.

    `$XDG_CACHE_HOME/pre-commit-terraform` and
    `$HOME/.cache/pre-commit-terraform` are both documented (README) and
    are what the Docker cache-mount instructions rely on.

    Args:
        tmp_repo: Temp git repo fixture.
        tmp_path: Temp dir fixture, used for the sandboxed `PATH`.
        cache_root_var: Env var under test, deciding the cache root.
    """
    base = tmp_path / 'fallback'
    # `XDG_CACHE_HOME` is itself the cache dir; `HOME` gains a `.cache`.
    cache_root_suffixes = {'XDG_CACHE_HOME': (), 'HOME': ('.cache',)}
    cache_root = base.joinpath(*cache_root_suffixes[cache_root_var])
    _write_stub(
        _CachedTool('tflint', 'tflint').stub_path(
            cache_root / 'pre-commit-terraform',
            PINNED_TFLINT_VERSION,
        ),
        'FALLBACK_TFLINT',
    )

    hook_run = _run_hook(
        'terraform_tflint.sh',
        [f'--hook-config=--tool-version={PINNED_TFLINT_VERSION}'],
        cwd=tmp_repo,
        env=_hook_env(
            {cache_root_var: str(base)},
            str(_sandbox_path_dir(tmp_path)),
        ),
    )

    combined = hook_run.stdout
    assert 'FALLBACK_TFLINT' in combined, combined
    assert DOWNLOAD_MSG not in combined, combined
    assert hook_run.returncode == 0, combined


# Every hook that wires a tool name into `common::resolve_tool_path`. The
# `tf`-sentinel hooks are pinned to `--tf-path=terraform` so the expected
# cache subdir stays independent of what the host has installed.
_TF_PATH_TERRAFORM = ('--hook-config=--tf-path=terraform',)
_WIRED_HOOKS = (
    pytest.param(
        _HookWiring(
            'terraform_tflint.sh',
            _CachedTool('tflint', 'tflint'),
            (),
        ),
        id='tflint',
    ),
    pytest.param(
        _HookWiring('terraform_trivy.sh', _CachedTool('trivy', 'trivy'), ()),
        id='trivy',
    ),
    pytest.param(
        _HookWiring('terraform_tfsec.sh', _CachedTool('tfsec', 'tfsec'), ()),
        id='tfsec',
    ),
    pytest.param(
        _HookWiring('terrascan.sh', _CachedTool('terrascan', 'terrascan'), ()),
        id='terrascan',
    ),
    pytest.param(
        _HookWiring(
            'terraform_docs.sh',
            _CachedTool('terraform-docs', 'terraform-docs'),
            (),
        ),
        id='terraform-docs',
    ),
    pytest.param(
        _HookWiring('tfupdate.sh', _CachedTool('tfupdate', 'tfupdate'), ()),
        id='tfupdate',
    ),
    pytest.param(
        _HookWiring(
            'infracost_breakdown.sh',
            _CachedTool('infracost', 'infracost'),
            (),
        ),
        id='infracost',
    ),
    pytest.param(
        _HookWiring(
            'terragrunt_fmt.sh',
            _CachedTool('terragrunt', 'terragrunt'),
            (),
        ),
        id='terragrunt-fmt',
    ),
    pytest.param(
        _HookWiring(
            'terragrunt_validate.sh',
            _CachedTool('terragrunt', 'terragrunt'),
            (),
        ),
        id='terragrunt-validate',
    ),
    pytest.param(
        _HookWiring(
            'terragrunt_validate_inputs.sh',
            _CachedTool('terragrunt', 'terragrunt'),
            (),
        ),
        id='terragrunt-validate-inputs',
    ),
    pytest.param(
        _HookWiring(
            'terragrunt_providers_lock.sh',
            _CachedTool('terragrunt', 'terragrunt'),
            (),
        ),
        id='terragrunt-providers-lock',
    ),
    pytest.param(
        _HookWiring(
            'terraform_fmt.sh',
            _CachedTool('terraform', 'terraform'),
            _TF_PATH_TERRAFORM,
        ),
        id='tf-fmt',
    ),
    pytest.param(
        _HookWiring(
            'terraform_validate.sh',
            _CachedTool('terraform', 'terraform'),
            _TF_PATH_TERRAFORM,
        ),
        id='tf-validate',
    ),
    pytest.param(
        _HookWiring(
            'terraform_providers_lock.sh',
            _CachedTool('terraform', 'terraform'),
            _TF_PATH_TERRAFORM,
        ),
        id='tf-providers-lock',
    ),
)


@pytest.mark.parametrize('wiring', _WIRED_HOOKS)
def test_hook_wires_its_own_tool_name(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
    wiring: _HookWiring,
) -> None:
    """Check each hook resolves `--tool-version` for the tool it wraps.

    A hook passing a wrong or misspelled tool name to
    `common::resolve_tool_path` would miss the cache entry seeded at
    `<tool>/<version>/<binary>` and try to download instead, so a cache
    hit here is what proves the wiring.

    Args:
        tmp_repo: Temp git repo fixture.
        cache_dir: Temp cache root fixture.
        tmp_path: Temp dir fixture, used for the sandboxed `PATH`.
        wiring: Hook under test plus the cache entry it must resolve.
    """
    _write_stub(
        wiring.cached_tool.stub_path(cache_dir, PINNED_ANY_VERSION),
        'WIRED_TOOL',
    )

    hook_run = _run_hook(
        wiring.hook_name,
        [
            *wiring.extra_args,
            f'--hook-config=--tool-version={PINNED_ANY_VERSION}',
        ],
        cwd=tmp_repo,
        env=_hook_env(
            _pct_cache_env(cache_dir),
            str(_sandbox_path_dir(tmp_path)),
        ),
    )

    combined = hook_run.stdout
    # Exit code is deliberately not asserted: a stub that ignores its
    # arguments makes several of these hooks fail for unrelated reasons.
    # Only the resolution decision is under test here.
    assert DOWNLOAD_MSG not in combined, combined
    assert NO_INSTALLER_MSG not in combined, combined


def test_tf_path_rejects_invalid_value(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check an unrecognized `--tf-path` + `--tool-version` errors."""
    hook_run = _run_hook(
        'terraform_fmt.sh',
        [
            '--hook-config=--tf-path=/some/custom/path',
            f'--hook-config=--tool-version={PINNED_TF_VERSION}',
        ],
        cwd=tmp_repo,
        env=_hook_env(
            _pct_cache_env(cache_dir),
            str(_sandbox_path_dir(tmp_path)),
        ),
    )

    combined = hook_run.stdout
    assert hook_run.returncode != 0, combined
    assert TF_PATH_INVALID_MSG in combined, combined
    assert DOWNLOAD_MSG not in combined, combined
    assert not list(cache_dir.iterdir()), combined


def test_checkov_ignores_tool_version(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
) -> None:
    """Check checkov (pip-distributed) treats `--tool-version` as a no-op.

    `terraform_checkov.sh` passes an empty tool name, so resolution returns
    early and the no-op is observable as an untouched cache root. Whether
    checkov itself then succeeds is out of scope, so its exit code is not
    asserted - a broken checkov install must not fail this test.
    """
    hook_run = _run_hook(
        'terraform_checkov.sh',
        ['--hook-config=--tool-version=1.2.3', '--args=--quiet'],
        cwd=tmp_repo,
        env=_hook_env(_pct_cache_env(cache_dir), os.environ['PATH']),
    )

    combined = hook_run.stdout
    assert not list(cache_dir.iterdir()), combined
    assert DOWNLOAD_MSG not in combined, combined
    assert NO_INSTALLER_MSG not in combined, combined
    assert TOOL_MISSING_MSG not in combined, combined


def test_actionable_error_when_tool_missing(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check the actionable error when unpinned and absent from PATH."""
    hook_run = _run_hook(
        'terraform_tflint.sh',
        [],
        cwd=tmp_repo,
        env=_hook_env(
            _pct_cache_env(cache_dir),
            str(_sandbox_path_dir(tmp_path)),
        ),
    )

    combined = hook_run.stdout
    assert hook_run.returncode != 0, combined
    assert TOOL_MISSING_MSG in combined, combined
    assert "'tflint' is required by" in combined, combined
    assert '--hook-config=--tool-version=' in combined, combined


def test_hook_runs_without_cpu_count_tools(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
    tmp_path: Path,
) -> None:
    """Check a hook still runs when no CPU-count tool is on `PATH`.

    `common::get_cpu_num` ends in `nproc || sysctl -n hw.ncpu || echo 1`
    (hooks/_common.sh:300, or :289 on a cgroup-v2 host), and
    `common::per_dir_hook` derives `parallelism_limit` from what it
    returns. With both probes hidden, that trailing fallback is the only
    thing left producing a value at all, and each assertion below pins a
    distinct way of losing it: drop the `|| echo 1` and the hook dies with
    127 mid-run, make it yield 0 instead of 1 and `parallelism_limit` goes
    negative, trading silent serial execution for a scary warning.

    Args:
        tmp_repo: Temp git repo fixture.
        cache_dir: Empty cache root fixture, seeded with a stub below.
        tmp_path: Temp dir fixture, used for the sandboxed `PATH`.
    """
    sandbox_path_dir = _sandbox_path_dir(tmp_path)
    for cpu_count_tool in _CPU_COUNT_TOOLS:
        # `missing_ok`: whether either got symlinked at all is exactly the
        # host-dependent thing this test exists to make irrelevant.
        (sandbox_path_dir / cpu_count_tool).unlink(missing_ok=True)

    _write_stub(
        _CachedTool('tflint', 'tflint').stub_path(
            cache_dir,
            PINNED_TFLINT_VERSION,
        ),
        'CACHED_TFLINT',
    )

    hook_run = _run_hook(
        'terraform_tflint.sh',
        [f'--hook-config=--tool-version={PINNED_TFLINT_VERSION}'],
        cwd=tmp_repo,
        env=_hook_env(_pct_cache_env(cache_dir), str(sandbox_path_dir)),
    )

    combined = hook_run.stdout
    assert 'CACHED_TFLINT' in combined, combined
    # `CPU` falls back to 1, which `common::per_dir_hook` treats as the
    # documented single-core case and stays quiet about (:407).
    assert PARALLELISM_CAPPED_MSG not in combined, combined
    assert hook_run.returncode == 0, combined


@pytest.mark.network
def test_real_download_on_cache_miss(  # pragma: win32 no cover
    tmp_repo: Path,
    cache_dir: Path,
) -> None:
    """Check a genuine end-to-end download on a cache miss (network)."""
    hook_run = _run_hook(
        'terraform_tflint.sh',
        [f'--hook-config=--tool-version={PINNED_TFLINT_VERSION}'],
        cwd=tmp_repo,
        env=_hook_env(_pct_cache_env(cache_dir), os.environ['PATH']),
    )

    combined = hook_run.stdout
    assert DOWNLOAD_MSG in combined, combined

    cached_bin = cache_dir / 'tflint' / PINNED_TFLINT_VERSION / 'tflint'
    assert os.access(cached_bin, os.X_OK), combined

    version_check = subprocess.run(  # noqa: S603
        (str(cached_bin), '--version'),
        capture_output=True,
        text=True,
        check=False,
        timeout=VERSION_CHECK_TIMEOUT_SECONDS,
    )
    assert version_check.returncode == 0, version_check.stderr
    assert PINNED_TFLINT_VERSION in version_check.stdout

    # 2 is tflint's own lint findings on the minimal fixture, not ours.
    assert hook_run.returncode in {0, 2}, combined
