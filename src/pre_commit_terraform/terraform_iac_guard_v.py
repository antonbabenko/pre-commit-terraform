"""Verify an explicit trusted repair through the released product CLI.

The pre-commit environment contains only this adapter. Product and scanner
environments are provisioned separately by the operator, never by the hook.
"""

from __future__ import annotations

import json
import logging
import os
import shutil
import signal

# Only explicit operator-provisioned executables and argv; never a shell.
import subprocess  # noqa: S404
import tempfile
import threading
import time
from argparse import Namespace
from contextlib import contextmanager
from pathlib import Path
from types import MappingProxyType
from typing import TYPE_CHECKING, Final, cast


if TYPE_CHECKING:
    from argparse import ArgumentParser
    from collections.abc import Callable, Iterator
    from types import FrameType


# Keep parser, process and Git concerns explicit.
# flake8: noqa: WPS202
CLI_SUBCOMMAND_NAME: Final[str] = 'iac-guard-v'
# Exact reviewed product/protocol pairs; future releases never self-promote.
SUPPORTED_PROTOCOLS: Final = MappingProxyType(
    {'1.0.4': 'report-v1'},
)
TIMEOUT: Final[int] = 600
CLEANUP_TIMEOUT: Final[int] = 15
POLL_INTERVAL: Final[float] = 0.1
PRIVATE_DIRECTORY_MODE: Final[int] = 0o700
LOGGER = logging.getLogger(__name__)
INCONCLUSIVE: Final[int] = 3
# Use the released schema, not a second definition of verification semantics.
REPORT_VALIDATOR: Final[str] = (
    'import json, sys; from importlib.resources import files; '
    'from jsonschema import validate; '
    'schema = files("iac_guard_v").joinpath("schemas/report-v1.schema.json"); '
    'validate(json.load(open(sys.argv[1])), json.loads(schema.read_text()))'
)
# JSON values enter as objects; the released schema establishes report shape.
JSON_LOADS: Final[Callable[[str], object]] = json.loads


def _require(message: str, *, condition: bool) -> None:
    if not condition:
        raise ValueError(message)


def populate_argument_parser(parser: ArgumentParser) -> None:
    """Accept only explicit inputs to the released local repair workflow."""
    parser.allow_abbrev = False
    parser.add_argument('--iacgv-python', type=Path, required=True)
    parser.add_argument('--local-trusted', action='store_true', required=True)
    parser.add_argument('--before', type=Path, required=True)
    parser.add_argument('--after', type=Path, required=True)
    parser.add_argument(
        '--framework',
        type=str,
        choices=('terraform',),
        required=True,
    )
    parser.add_argument('--target', action='append', required=True)
    parser.add_argument('--checkov-executable', type=Path, required=True)


def _executable(path: Path, snapshots: tuple[Path, Path]) -> str:
    _require(
        f'Expected an absolute, executable operator-provisioned path: {path}',
        condition=path.is_absolute()
        and path.is_file()
        and os.access(path, os.X_OK),
    )
    # Preserve the venv selection as well as checking its final interpreter.
    # A candidate bin/python symlink to a trusted system binary is still a
    # candidate-owned Python environment. Directory aliases must not hide it.
    locations = (path.parent.resolve() / path.name, path.resolve())
    _require(
        'Product and scanner runtimes must be outside both snapshots.',
        condition=not any(
            location.is_relative_to(snapshot)
            for location in locations
            for snapshot in snapshots
        ),
    )
    # Resolving a venv Python symlink would lose the selected environment.
    return str(path)


class _Arguments(Namespace):
    iacgv_python: Path
    local_trusted: bool
    before: Path
    after: Path
    framework: str
    target: list[str]
    checkov_executable: Path


def verification_command(
    parsed: Namespace,
    root: Path,
    report: Path,
) -> list[str]:
    """Resolve snapshots from Git root and preserve literal product arguments.

    Returns:
        list[str]: The published verify invocation, without shell expansion.
    """
    args = cast('_Arguments', parsed)
    before, after = (
        (root / args.before).resolve(),
        (root / args.after).resolve(),
    )
    _require(
        'Provide distinct existing trusted before/after directories.',
        condition=before.is_dir() and after.is_dir() and before != after,
    )
    _require(
        'Reports must remain outside both snapshots.',
        condition=not any(
            report.is_relative_to(path) for path in (before, after)
        ),
    )
    selectors: list[str] = []
    for target in args.target:
        selectors.extend(('--target', target))
    return [
        _executable(args.iacgv_python, (before, after)),
        '-I',
        '-B',
        '-m',
        'iac_guard_v.cli',
        'verify',
        '--before',
        str(before),
        '--after',
        str(after),
        '--framework',
        args.framework,
        '--local-trusted',
        '--checkov-executable',
        _executable(args.checkov_executable, (before, after)),
        *selectors,
        '--format',
        'json',
        '--output',
        str(report),
        '--quiet',
    ]


def _git_path(git: str, option: str) -> Path:
    # Git is resolved through the operator PATH, as in other hooks.
    output = subprocess.check_output(  # noqa: S603
        [git, 'rev-parse', option],
        text=True,
        timeout=TIMEOUT,
    )
    return Path(output.removesuffix('\n')).resolve(strict=True)


class HookRun:
    """Retain an exclusive report and process logs for each invocation."""

    def __init__(self, parsed: Namespace) -> None:
        """Find actual Git metadata, including linked worktrees."""
        git = shutil.which('git')
        _require('Git must be installed.', condition=git is not None)
        self.root = _git_path(str(git), '--show-toplevel')
        metadata = _git_path(str(git), '--absolute-git-dir')
        # Check overlap before any writes, including metadata directories.
        verification_command(
            parsed,
            self.root,
            metadata / 'iac-guard-v/runs/report.json',
        )
        reports = metadata
        for name in ('iac-guard-v', 'runs'):
            reports /= name
            _require(
                'Report directories must not be symlinks.',
                condition=not reports.is_symlink(),
            )
            reports.mkdir(mode=PRIVATE_DIRECTORY_MODE, exist_ok=True)
        self.directory = Path(tempfile.mkdtemp(prefix='run-', dir=reports))
        self.report = self.directory / 'report.json'
        self.cancelled = False

    def verify(self, parsed: Namespace) -> int:
        """Invoke the product once, preserving its classifications and exits.

        Returns:
            int: Published exit, or 3 when transport evidence is invalid.
        """
        command = verification_command(parsed, self.root, self.report)
        runtime = self._process(
            [
                command[0],
                '-I',
                '-B',
                '-c',
                (
                    'from importlib.metadata import version; '
                    'print(version("iac-guard-v"))'
                ),
            ],
            'runtime',
        )
        product_version = (
            (self.directory / 'runtime.stdout.log').read_text().strip()
        )
        protocol = SUPPORTED_PROTOCOLS.get(product_version)
        _require(
            'Runtime requires iac-guard-v 1.0.4 with report-v1 '
            'and cooperative cancellation; '
            'see runtime logs.',
            condition=runtime == 0 and protocol is not None,
        )
        code = self._process(command, 'verification')
        LOGGER.warning('IaC-Guard-V process exit: %s', code)
        if code not in {0, 1, INCONCLUSIVE}:
            self.invalidate_report()
            return code if code > 0 else INCONCLUSIVE
        _require(
            'Canonical report missing or symlinked; see verification logs.',
            condition=self.report.is_file() and not self.report.is_symlink(),
        )
        validation = self._process(
            [command[0], '-I', '-B', '-c', REPORT_VALIDATOR, str(self.report)],
            'schema',
        )
        _require(
            'Invalid or incomplete canonical report; see schema logs.',
            condition=validation == 0,
        )
        payload = cast(
            'dict[str, object]',
            JSON_LOADS(self.report.read_text()),
        )
        # The schema validates headers/types; compare transport consistency.
        _require(
            'Canonical verdict/exit does not match the product process.',
            condition=payload.get('schema_version') == protocol
            and payload.get('result_kind')
            in {'verification', 'operational_uncertainty'}
            and payload['exit_code'] == code
            and payload.get('verdict')
            == {0: 'VERIFIED', 1: 'FAILED', 3: 'INCONCLUSIVE'}[code],
        )
        LOGGER.warning(
            '%s; canonical report: %s',
            payload['verdict'],
            self.report,
        )
        return code

    def _interrupt(self, _signum: int, _frame: FrameType | None) -> None:
        # Latch rather than raise inside Popen: ownership must be established
        # before cleanup can run. Repeated signals never interrupt cleanup.
        self.cancelled = True

    @contextmanager
    def signals(self) -> Iterator[None]:
        """Handle CLI signals temporarily; keep threaded callers unchanged."""
        if threading.current_thread() is not threading.main_thread():
            yield
            return
        previous = {
            sig: signal.getsignal(sig)
            for sig in (signal.SIGINT, signal.SIGTERM)
        }
        try:
            for sig in previous:
                signal.signal(sig, self._interrupt)
            yield
        finally:
            for sig, handler in previous.items():
                signal.signal(sig, handler)

    def invalidate_report(self) -> None:
        """Retain rejected evidence outside the canonical report path."""
        if self.report.exists() or self.report.is_symlink():
            try:
                self.report.rename(self.directory / 'unaccepted-report.json')
            except OSError as error:
                LOGGER.warning(
                    'Could not quarantine rejected report: %s',
                    error,
                )

    @staticmethod
    def _stop(process: subprocess.Popen[str]) -> None:
        # The qualified product cleans its separately owned scanner session.
        # Keep the verifier alive long enough to complete that bounded cleanup.
        process.terminate()
        try:
            process.wait(timeout=CLEANUP_TIMEOUT)
        except subprocess.TimeoutExpired:
            LOGGER.warning(
                'Verifier did not acknowledge cancellation; '
                'scanner cleanup unconfirmed.',
            )
            # The unreaped session leader reserves this process group identity.
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=CLEANUP_TIMEOUT)

    def _process(self, command: list[str], label: str) -> int:
        _require(
            'Native verification requires POSIX cleanup; '
            'use Linux Docker on Windows.',
            condition=os.name == 'posix',
        )
        with (
            (self.directory / f'{label}.stdout.log').open('x') as stdout,
            (self.directory / f'{label}.stderr.log').open('x') as stderr,
        ):
            process = subprocess.Popen(  # noqa: S603 — explicit trusted executable, literal argv
                command,
                cwd=self.root,
                env=dict(os.environ, PYTHONDONTWRITEBYTECODE='1'),
                stdout=stdout,
                stderr=stderr,
                text=True,
                start_new_session=True,
            )
            try:
                return self._wait(process, command)
            except BaseException:
                try:
                    self._stop(process)
                finally:
                    self.invalidate_report()
                raise

    def _check_cancellation(self) -> None:
        if self.cancelled:
            raise KeyboardInterrupt

    def _wait(self, process: subprocess.Popen[str], command: list[str]) -> int:
        deadline = time.monotonic() + TIMEOUT
        while True:
            self._check_cancellation()
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise subprocess.TimeoutExpired(command, TIMEOUT)
            try:
                code = process.wait(timeout=min(POLL_INTERVAL, remaining))
            except subprocess.TimeoutExpired:
                continue
            self._check_cancellation()
            return code

    def execute(self, args: Namespace) -> int:
        """Reject cancellation even after the verifier has written its report.

        Returns:
            int: Product classification when no cancellation was observed.
        """
        with self.signals():
            code = self.verify(args)
        self._check_cancellation()
        return code


def invoke_cli_app(args: Namespace) -> int:
    """Return nonzero on setup, execution or evidence transport errors.

    Returns:
        int: Product exit or inconclusive transport failure. pre-commit itself
        normalizes nonzero hook statuses to 1.
    """
    invocation: HookRun | None = None
    try:  # noqa: WPS229 — allocation, diagnostics and verification share one boundary
        invocation = HookRun(args)
        LOGGER.warning('IaC-Guard-V evidence: %s', invocation.directory)
        return invocation.execute(args)
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        LOGGER.warning('IaC-Guard-V setup/transport error: %s', error)
        if invocation is not None:
            invocation.invalidate_report()
        return INCONCLUSIVE
    except KeyboardInterrupt:
        if invocation is not None:
            invocation.invalidate_report()
        LOGGER.warning(
            'IaC-Guard-V execution interrupted; no verified result.',
        )
        return INCONCLUSIVE
