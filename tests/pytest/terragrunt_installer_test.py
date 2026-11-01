"""Network-free tests for the GitHub release lookup in `terragrunt.sh`.

Each test runs the real `tools/install/terragrunt.sh` as a subprocess, with
a stub `curl` in front of `PATH` replaying canned GitHub API replies, and
asserts on its exit code, its output and the requests the stub recorded -
never on a bash-internal function name.

The logic under test (`common::gh_api_get` error handling and pagination)
lives in the shared `tools/install/_common.sh`; `terragrunt.sh` is used as
the representative installer because it is the paginated, pure-binary case
from issue #1023.

NOTE: the module-level `pytestmark` skip leaves every function body below
unexecuted on Windows, and `covdefaults` gates coverage at 100%, so every
module-level `def` in this file needs a `# pragma: win32 no cover`.
"""

from __future__ import annotations

import json
import os
import shutil
import stat
import subprocess
import sys
from pathlib import Path
from typing import NamedTuple

import pytest


INSTALLER_TIMEOUT_SECONDS = 60

LATEST = 'latest'
PINNED_VERSION = '0.50.0'
OLD_PINNED_VERSION = '0.49.0'
HTTP_OK = '200'

GITHUB_HOST = 'github.com'
API_HOST = 'api.github.com'
OWNER = 'gruntwork-io'
TOOL = 'terragrunt'
PER_PAGE = 100
TARGET_OS = 'linux'
TARGET_ARCH = 'amd64'

RELEASES_PATH = f'{OWNER}/{TOOL}/releases'
INSTALLER = Path(__file__).resolve().parents[2] / f'tools/install/{TOOL}.sh'
API_URL = f'https://{API_HOST}/repos/{RELEASES_PATH}'
LATEST_URL = f'{API_URL}/latest'
FIRST_PAGE_URL = f'{API_URL}?per_page={PER_PAGE}&page=1'
SECOND_PAGE_URL = f'{API_URL}?per_page={PER_PAGE}&page=2'
DOWNLOAD_URL = f'https://{GITHUB_HOST}/{RELEASES_PATH}/download'
ASSET_NAME = f'{TOOL}_{TARGET_OS}_{TARGET_ARCH}'
ASSET_URL = f'{DOWNLOAD_URL}/v{PINNED_VERSION}/{ASSET_NAME}'
OLD_ASSET_URL = f'{DOWNLOAD_URL}/v{OLD_PINNED_VERSION}/{ASSET_NAME}'
ASSET_TEXT = f'{TOOL} binary'
# Installers are bash scripts; no fallback - a missing `bash` skips the tests.
BASH = shutil.which('bash')

# GitHub pretty-prints its JSON: every asset URL sits on a line of its own.
HIT_BODY = json.dumps([{'browser_download_url': ASSET_URL}], indent=2)
MISS_BODY = json.dumps([{'browser_download_url': OLD_ASSET_URL}], indent=2)
# GitHub's rate-limit message embeds the caller's IP. 203.0.113.7 is from
# RFC 5737's TEST-NET-3 documentation block, so it is never a real host; the
# last octet (`7`) is arbitrary - only the message wording matters here.
RATE_LIMIT_BODY = 'API rate limit exceeded for 203.0.113.7.'

# Diagnostics of `common::gh_api_get` and its callers in
# `tools/install/_common.sh` (`common::colorify` writes them to stderr).
ERROR_PREFIX = 'ERROR:'
RATE_LIMIT_MSG = 'rate limit exceeded'
AUTH_HINT = 'GITHUB_TOKEN'
HTTP_ERROR_MSG = 'failed with HTTP'
TRANSPORT_MSG = 'failed to contact GitHub API'
NOT_FOUND_MSG = f"could not find a '{TOOL}' release asset"
DOWNLOAD_FAILED_MSG = f"Failed to download '{TOOL}' release asset"

# Replays the next canned reply from `$STUB_CURL_DIR` and records the URL it
# was asked for. A reply file `<n>` holds the HTTP status (or `exit:<code>`
# for a transport failure) on its first line and the body on the rest.
# Mimics the only `curl` options the installers rely on: `-w` (appends the
# formatted status to the body) and `-f` (exit 22 on HTTP >= 400).
STUB_CURL = r"""#!/usr/bin/env bash
dir=$STUB_CURL_DIR
tag='%{http_code}'
printf '%s\n' "${!#}" >> "$dir/requests"
reply="$dir/$(grep -c '' "$dir/requests")"
[[ -f $reply ]] || exit 99
read -r status < "$reply"
[[ $status == exit:* ]] && exit "${status#exit:}"
for arg; do
  [[ $prev == -w ]] && format=$arg
  [[ $arg == -f && $status -ge 400 ]] && exit 22
  prev=$arg
done
tail -n +2 "$reply"
printf '%s' "${format//$tag/$status}"
"""

pytestmark = [
    pytest.mark.skipif(
        sys.platform == 'win32',
        reason=(
            'Hook-subprocess tests are skipped on Windows: this repository '
            'does not fully support/guarantee Windows hook execution '
            '(see README.md / .github/CONTRIBUTING.md).'
        ),
    ),
    pytest.mark.skipif(
        BASH is None,
        reason='bash was not found on PATH.',
    ),
]


class _Run(NamedTuple):
    """Outcome of one installer run against the stub `curl`."""

    output: str
    returncode: int
    requests: list[str]
    workdir: Path


def _run_installer(  # pragma: win32 no cover
    tmp_path: Path,
    version: str,
    *replies: tuple[str, str],
) -> _Run:
    """Run the installer against a stub `curl` replaying `replies`.

    Args:
        tmp_path: Temp dir fixture, holding the stub and the workdir.
        version: Value for the installer's version environment variable.
        replies: `(status, body)` per expected `curl` call, in order; a
            status of `exit:<code>` makes that call fail like a
            transport error.

    Returns:
        Exit code, merged stdout/stderr, URLs requested in order and the
        directory the installer downloads into.
    """
    assert BASH is not None  # Guaranteed by the module-level skipif.
    stub_dir = tmp_path / 'stub'
    work_dir = tmp_path / 'work'
    stub_dir.mkdir()
    work_dir.mkdir()
    (stub_dir / 'curl').write_text(STUB_CURL, encoding='utf-8')
    (stub_dir / 'curl').chmod(stat.S_IRWXU)
    (stub_dir / 'requests').touch()
    for number, reply in enumerate(replies, start=1):
        (stub_dir / str(number)).write_text(
            '\n'.join(reply),
            encoding='utf-8',
        )
    installer = subprocess.run(  # noqa: S603
        (BASH, str(INSTALLER)),
        cwd=work_dir,
        env={
            'PATH': os.pathsep.join((str(stub_dir), os.environ['PATH'])),
            'LC_ALL': 'C',
            'PRE_COMMIT_COLOR': 'never',
            'STUB_CURL_DIR': str(stub_dir),
            'TARGETARCH': TARGET_ARCH,
            'TARGETOS': TARGET_OS,
            f'{TOOL.upper()}_VERSION': version,
        },
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        check=False,
        timeout=INSTALLER_TIMEOUT_SECONDS,
    )
    return _Run(
        installer.stdout,
        installer.returncode,
        (stub_dir / 'requests').read_text(encoding='utf-8').splitlines(),
        work_dir,
    )


@pytest.mark.parametrize(
    ('version', 'first_url'),
    (
        pytest.param(LATEST, LATEST_URL, id='latest'),
        pytest.param(PINNED_VERSION, FIRST_PAGE_URL, id='pinned'),
    ),
)
# Param IDs: a bare HTTP code where the status alone decides the diagnostic,
# and a body-qualified name where several cases share one status (the three
# 403s) and differ only in the response body / resulting diagnostic.
@pytest.mark.parametrize(
    ('reply', 'diagnostic'),
    (
        pytest.param(
            ('403', RATE_LIMIT_BODY),
            RATE_LIMIT_MSG,
            id='403-rate-limit',
        ),
        pytest.param(
            ('403', 'Rate Limit Exceeded'),
            RATE_LIMIT_MSG,
            id='403-rate-limit-any-case',
        ),
        pytest.param(
            ('429', 'Too Many Requests'),
            RATE_LIMIT_MSG,
            id='429',
        ),
        pytest.param(
            ('403', 'Resource not accessible by personal access token'),
            f'{HTTP_ERROR_MSG} 403',
            id='403-access-denied',
        ),
        pytest.param(
            ('404', 'Not Found'),
            f'{HTTP_ERROR_MSG} 404',
            id='404',
        ),
        pytest.param(
            ('502', 'Bad Gateway'),
            f'{HTTP_ERROR_MSG} 502',
            id='502',
        ),
        pytest.param(
            ('exit:6', ''),
            TRANSPORT_MSG,
            id='transport-error',
        ),
    ),
)
def test_api_failure_aborts_after_first_request(  # pragma: win32 no cover
    tmp_path: Path,
    version: str,
    first_url: str,
    reply: tuple[str, str],
    diagnostic: str,
) -> None:
    """Check a failed API call ends the install instead of being paged on.

    Regression test for issue #1023: a rate-limited `403` used to be taken
    for release data, so the installer burned up to 20 requests and ended
    with a misleading "not found" error.
    """
    run = _run_installer(tmp_path, version, reply)

    assert run.returncode == 1
    assert diagnostic in run.output
    assert run.output.count(ERROR_PREFIX) == 1
    # The `GITHUB_TOKEN` hint belongs to rate-limit errors only.
    assert (AUTH_HINT in run.output) is (diagnostic == RATE_LIMIT_MSG)
    assert run.requests == [first_url]


@pytest.mark.parametrize(
    'empty_page',
    (
        pytest.param('[]', id='compact'),
        pytest.param('[\n\n]', id='pretty-printed'),
    ),
)
def test_pagination_stops_at_empty_page(  # pragma: win32 no cover
    tmp_path: Path,
    empty_page: str,
) -> None:
    """Check the first empty release page ends the pagination.

    Regression test: GitHub pretty-prints an empty array with blank lines
    between the brackets, which the former byte-exact `[]` check never
    matched, so every lookup of a missing version burned all 20 pages.
    """
    run = _run_installer(
        tmp_path,
        PINNED_VERSION,
        (HTTP_OK, MISS_BODY),
        (HTTP_OK, empty_page),
    )

    assert run.returncode == 1
    assert NOT_FOUND_MSG in run.output
    assert run.requests == [FIRST_PAGE_URL, SECOND_PAGE_URL]


@pytest.mark.parametrize(
    ('version', 'bodies', 'api_urls'),
    (
        pytest.param(LATEST, (HIT_BODY,), (LATEST_URL,), id='latest'),
        pytest.param(
            PINNED_VERSION,
            (MISS_BODY, HIT_BODY),
            (FIRST_PAGE_URL, SECOND_PAGE_URL),
            id='pinned-on-second-page',
        ),
    ),
)
def test_installs_asset_listed_in_api_body(  # pragma: win32 no cover
    tmp_path: Path,
    version: str,
    bodies: tuple[str, ...],
    api_urls: tuple[str, ...],
) -> None:
    """Check the asset URL is picked out of the API body and downloaded."""
    run = _run_installer(
        tmp_path,
        version,
        *((HTTP_OK, body) for body in bodies),
        (HTTP_OK, ASSET_TEXT),
    )

    assert run.returncode == 0
    assert run.requests == [*api_urls, ASSET_URL]
    assert (run.workdir / TOOL).read_bytes() == ASSET_TEXT.encode()


def test_asset_download_failure_aborts_install(  # pragma: win32 no cover
    tmp_path: Path,
) -> None:
    """Check an HTTP error on the asset itself fails the install."""
    run = _run_installer(
        tmp_path,
        LATEST,
        (HTTP_OK, HIT_BODY),
        ('404', 'Not Found'),
    )

    assert run.returncode == 1
    assert DOWNLOAD_FAILED_MSG in run.output
    assert run.requests == [LATEST_URL, ASSET_URL]
