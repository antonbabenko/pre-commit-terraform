"""Opt-in POSIX process tests; run explicitly on Linux and macOS.

Keep OS process exercises separate from the deterministic Python unit matrix.
The unit suite exercises transport error paths with typed process doubles;
these tests require actual children, signals, and process identity checks.
"""

# Standalone test namespace, matching the existing acceptance runner.
# ruff: noqa: INP001
# OS scenarios and small ownership helpers stay flat rather than nested.
# flake8: noqa: WPS202

from __future__ import annotations

import os
import signal
import subprocess
import sys
import threading
import time
from pathlib import Path
from typing import TYPE_CHECKING, Final, Protocol, cast

import pytest

from pre_commit_terraform import terraform_iac_guard_v as hook


if TYPE_CHECKING:
    from collections.abc import Callable

    from pre_commit_terraform.terraform_iac_guard_v import _Arguments


class ControllerFactory(Protocol):
    """Only the keyword-only Thread constructor subset used by this fixture."""

    def __call__(self, *, target: Callable[[], None]) -> threading.Thread:
        """Construct a controller with no untyped argument forwarding."""
        ...


CONTROLLER: Final[ControllerFactory] = threading.Thread

POSIX_ONLY = pytest.mark.skipif(
    sys.platform == 'win32',
    reason='Native process cleanup requires POSIX',
)
PYTHON_CODE = '-c'
POLL_INTERVAL = 0.01
WAIT_LIMIT = 5
SUPERVISOR = """
import json, os, signal, subprocess, sys, time
from pathlib import Path
pids, report, token, startup_timeout = sys.argv[1:]
deadline = time.monotonic() + float(startup_timeout)
while not Path(pids).with_suffix(".start").exists():
    if time.monotonic() >= deadline:
        raise SystemExit(3)
    time.sleep(.01)
child = subprocess.Popen(
    [sys.executable, '-c', 'import time; time.sleep(30)', token],
    start_new_session=True,
)
def cancel(*args):
    child.terminate()
    child.wait(timeout=3)
    raise SystemExit(3)
signal.signal(signal.SIGTERM, cancel)
Path(report).write_text('{"verdict":"VERIFIED","exit_code":0}')
ready = Path(pids).with_suffix(".tmp")
ready.write_text(json.dumps([os.getpid(), child.pid]))
ready.replace(pids)
while True: time.sleep(.05)
"""


def _alive(pid: int, token: str) -> bool:
    """Check this fixture's argv identity, excluding zombie/reused PIDs.

    Returns:
        bool: The original owned process remains running.
    """
    if sys.platform == 'linux':
        proc = Path('/proc') / str(pid)
        try:
            command, state = _linux_identity(proc)
        except FileNotFoundError:
            return False
        return token.encode() in command and not state.startswith('Z')
    status = subprocess.run(  # noqa: S603 — fixed system ps and numeric owned PID
        ['/bin/ps', '-o', 'stat=,args=', '-p', str(pid)],
        capture_output=True,
        text=True,
        check=False,
    )
    parts = status.stdout.strip().split(maxsplit=1)
    return (
        len(parts) == len(('stat', 'args'))
        and not parts[0].startswith('Z')
        and token in parts[1]
    )


def _ready(path: Path) -> list[int]:
    deadline = time.monotonic() + WAIT_LIMIT
    while not path.exists() and time.monotonic() < deadline:
        time.sleep(POLL_INTERVAL)
    return cast('list[int]', hook.JSON_LOADS(path.read_text(encoding='utf-8')))


@pytest.mark.parametrize('mode', ('int', 'term', 'repeated', 'timeout'))
@POSIX_ONLY
def test_cooperative_cleanup(  # noqa: WPS210,WPS218 — keep process identities and independent assertions explicit
    repair: _Arguments,
    repository: Path,
    monkeypatch: pytest.MonkeyPatch,
    mode: str,
) -> None:
    """Stop a separately sessioned descendant; quarantine stale output."""
    run = hook.HookRun(repair)
    scanner = repository / 'cooperative fixture.py'
    scanner.write_text(SUPERVISOR)
    pids = repository / 'pids.json'
    token = repository.parent.name
    command = [
        sys.executable,
        str(scanner),
        str(pids),
        str(run.report),
        token,
        str(WAIT_LIMIT),
    ]
    if mode == 'timeout':
        monkeypatch.setattr(hook, 'TIMEOUT', 1)
    wait = run._wait  # noqa: SLF001 — preserve the real timeout loop

    def wait_when_ready(  # noqa: WPS430 — synchronize before the real deadline starts
        process: subprocess.Popen[str],
        arguments: list[str],
    ) -> int:
        pids.with_suffix('.start').touch()
        supervisor, descendant = _ready(pids)
        assert supervisor == process.pid
        assert _alive(supervisor, token)
        assert _alive(descendant, token)
        return wait(process, arguments)

    monkeypatch.setattr(run, '_wait', wait_when_ready)
    unrelated = subprocess.Popen(  # noqa: S603 — trusted interpreter, literal isolation fixture
        [
            sys.executable,
            PYTHON_CODE,
            'import time; time.sleep(30)',
            'unrelated',
        ],
    )
    input_hashes = _snapshot_bytes(repository)

    def interrupt() -> None:  # noqa: WPS430 — precisely typed controller closure
        _interrupt_fixture(mode, pids)

    controller = CONTROLLER(target=interrupt)
    try:  # noqa: WPS229 — keep interruption assertions next to guaranteed cleanup
        with run.signals():
            controller.start()
            expected = (
                subprocess.TimeoutExpired
                if mode == 'timeout'
                else KeyboardInterrupt
            )
            with pytest.raises(expected):
                run._process(command, 'cancellation')  # noqa: SLF001 — transport ownership boundary
            controller.join(timeout=WAIT_LIMIT)
        identities = _ready(pids)
        assert not controller.is_alive()
        assert all(not _alive(pid, token) for pid in identities)
        assert unrelated.poll() is None
        assert not run.report.exists()
        assert (run.directory / 'unaccepted-report.json').is_file()
        assert (run.directory / 'cancellation.stderr.log').is_file()
        assert all(
            path.read_bytes() == original
            for path, original in input_hashes.items()
        )
    finally:
        _finish_fixture(unrelated, controller, pids, token)


@POSIX_ONLY
def test_supervisor_startup_deadline(tmp_path: Path) -> None:
    """An unacknowledged fixture exits before creating a scanner or report."""
    pids = tmp_path / 'pids.json'
    report = tmp_path / 'report.json'
    completed = subprocess.run(  # noqa: S603 — current interpreter and literal fixture argv
        [
            sys.executable,
            PYTHON_CODE,
            SUPERVISOR,
            str(pids),
            str(report),
            tmp_path.name,
            str(POLL_INTERVAL),
        ],
        check=False,
        timeout=WAIT_LIMIT,
    )
    assert completed.returncode == hook.INCONCLUSIVE
    assert not pids.exists()
    assert not report.exists()


@POSIX_ONLY
def test_escalation_stays_in_owned_session(
    repair: _Arguments,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Bound unresponsive verifier cleanup to its owned session."""
    run = hook.HookRun(repair)
    monkeypatch.setattr(hook, 'CLEANUP_TIMEOUT', 0.1)
    process = subprocess.Popen(
        [
            sys.executable,
            '-c',
            (
                'import signal,time; '
                'signal.signal(signal.SIGTERM, signal.SIG_IGN); '
                'print("ready",flush=True); time.sleep(30)'
            ),
        ],
        start_new_session=True,
        stdout=subprocess.PIPE,
        text=True,
    )
    assert process.stdout is not None
    try:  # noqa: WPS229 — readiness, termination and exit evidence share ownership
        assert process.stdout.readline() == 'ready\n'
        run._stop(process)  # noqa: SLF001 — bounded cleanup boundary
        assert process.returncode == -signal.SIGKILL
    finally:
        process.stdout.close()
        _reap(process)


def _cleanup_owned(identities: list[int], token: str) -> None:
    for pid in identities:
        if _alive(pid, token):
            os.kill(pid, signal.SIGKILL)


@POSIX_ONLY
def test_fixture_cleanup_isolated() -> None:
    """The fallback reaper checks the owned argv identity."""
    token = f'fixture-owned-cleanup-{os.getpid()}'
    owned = subprocess.Popen(  # noqa: S603 — owned current-interpreter fixture
        [sys.executable, PYTHON_CODE, 'import time; time.sleep(30)', token],
    )
    unrelated = subprocess.Popen(  # noqa: S603 — trusted interpreter, literal isolation fixture
        [sys.executable, PYTHON_CODE, 'import time; time.sleep(30)', 'other'],
    )
    try:  # noqa: WPS229 — cleanup proof and unrelated-process control share ownership
        _cleanup_owned([owned.pid, unrelated.pid], token)
        owned.wait(timeout=WAIT_LIMIT)
        assert owned.returncode == -signal.SIGKILL
        assert unrelated.poll() is None
    finally:
        for process in (owned, unrelated):
            _reap(process)


def _linux_identity(proc: Path) -> tuple[bytes, str]:
    command = (proc / 'cmdline').read_bytes()
    state = (proc / 'stat').read_text(encoding='utf-8').split(') ')[1]
    return command, state


def _snapshot_bytes(repository: Path) -> dict[Path, bytes]:
    snapshots = tuple(
        repository / name / 'main.tf' for name in ('before', 'after')
    )
    for snapshot in snapshots:
        snapshot.write_bytes(b'protected snapshot\n')
    return {original: original.read_bytes() for original in snapshots}


def _interrupt_fixture(mode: str, pids: Path) -> None:
    _ready(pids)
    if mode != 'timeout':
        signum = signal.SIGINT if mode == 'int' else signal.SIGTERM
        os.kill(os.getpid(), signum)
        if mode == 'repeated':
            os.kill(os.getpid(), signal.SIGINT)
            os.kill(os.getpid(), signal.SIGTERM)


def _finish_fixture(
    unrelated: subprocess.Popen[bytes],
    controller: threading.Thread,
    pids: Path,
    token: str,
) -> None:
    unrelated.terminate()
    unrelated.wait(timeout=WAIT_LIMIT)
    controller.join(timeout=WAIT_LIMIT)
    _cleanup_owned(_ready(pids), token)


def _reap(process: subprocess.Popen[str] | subprocess.Popen[bytes]) -> None:
    process.kill()
    process.wait(timeout=WAIT_LIMIT)
