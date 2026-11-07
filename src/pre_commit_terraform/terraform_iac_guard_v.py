"""Verify an explicit trusted repair through the released product CLI.

The pre-commit environment contains only this adapter. Product and scanner
environments are provisioned separately by the operator, never by the hook.
"""

from __future__ import annotations

import json
import logging
import os
import shutil

# Only explicit operator-provisioned executables and argv; never a shell.
import subprocess  # noqa: S404
import tempfile
from argparse import Namespace
from pathlib import Path
from typing import TYPE_CHECKING, Final, cast


if TYPE_CHECKING:
    from argparse import ArgumentParser


# Eight small module members keep parser, process and Git concerns explicit.
# flake8: noqa: WPS202
CLI_SUBCOMMAND_NAME: Final[str] = 'iac-guard-v'
VERSION: Final[str] = '1.0.2'
TIMEOUT: Final[int] = 600
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
    parser.add_argument('--framework', choices=('terraform',), required=True)
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
    args = _Arguments(**cast('dict[str, object]', parsed.__dict__))
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
        _require(
            'Runtime requires published iac-guard-v==1.0.2; see runtime logs.',
            condition=runtime == 0
            and (self.directory / 'runtime.stdout.log').read_text().strip()
            == VERSION,
        )
        code = self._process(command, 'verification')
        LOGGER.warning('IaC-Guard-V process exit: %s', code)
        if code not in {0, 1, INCONCLUSIVE}:
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
            json.loads(self.report.read_text()),
        )
        # The schema validates headers/types; compare transport consistency.
        _require(
            'Canonical verdict/exit does not match the product process.',
            condition=payload.get('result_kind')
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

    def _process(self, command: list[str], label: str) -> int:
        with (
            (self.directory / f'{label}.stdout.log').open('x') as stdout,
            (self.directory / f'{label}.stderr.log').open('x') as stderr,
        ):
            completed = subprocess.run(  # noqa: S603 — explicit trusted executable, literal argv
                command,
                cwd=self.root,
                env=dict(os.environ, PYTHONDONTWRITEBYTECODE='1'),
                stdout=stdout,
                stderr=stderr,
                check=False,
                timeout=TIMEOUT,
            )
        return completed.returncode


def invoke_cli_app(args: Namespace) -> int:
    """Return nonzero on setup, execution or evidence transport errors.

    Returns:
        int: Product exit or inconclusive transport failure. pre-commit itself
        normalizes nonzero hook statuses to 1.
    """
    try:  # noqa: WPS229 — allocation, diagnostics and verification share one boundary
        invocation = HookRun(args)
        LOGGER.warning('IaC-Guard-V evidence: %s', invocation.directory)
        return invocation.verify(args)
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        LOGGER.warning('IaC-Guard-V setup/transport error: %s', error)
        return INCONCLUSIVE
    except KeyboardInterrupt:
        LOGGER.warning(
            'IaC-Guard-V execution interrupted; no verified result.',
        )
        return INCONCLUSIVE
