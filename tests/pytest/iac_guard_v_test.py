"""Deterministic transport tests; real product tests run separately."""

# Repeated boundary assertions keep failure scenarios independently legible.
# flake8: noqa: WPS204

from __future__ import annotations

import json
import shutil
import subprocess
from argparse import ArgumentParser, Namespace
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import Protocol

import pytest
from pre_commit_terraform import _cli
from pre_commit_terraform import terraform_iac_guard_v as hook


BEFORE = 'before'
AFTER = 'after'
REPORT = 'report'
USAGE_ERROR = 2
EXECUTION_ERROR = 4
REPEATED_RUNS = 2


class Transport(Protocol):
    """Typed process-double installer with optional scenario arguments."""

    def __call__(
        self,
        code: int,
        report: str | None = None,
        schema: int = 0,
    ) -> None:
        """Select product and report outcomes."""
        ...


@pytest.fixture
def repository(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Path:
    """Create a disposable repository, retaining spaces in its path.

    Returns:
        Path: Repository root.
    """
    root = tmp_path / 'repo with spaces '
    root.mkdir()
    git = shutil.which('git')
    assert git is not None
    subprocess.run([git, 'init', '-q', str(root)], check=True)  # noqa: S603 — resolved executable and fixed argv
    monkeypatch.chdir(root)
    return root


@pytest.fixture
def repair(repository: Path) -> Namespace:
    """Parse a benign explicit repair request.

    Returns:
        Namespace: Parsed operator-controlled arguments.
    """
    executable = repository / 'python'
    executable.write_text('#!/bin/sh\nexit 0\n')
    executable.chmod(hook.PRIVATE_DIRECTORY_MODE)
    for name in (BEFORE, AFTER):
        (repository / name).mkdir()
    parser = ArgumentParser()
    hook.populate_argument_parser(parser)
    return parser.parse_args(
        [
            '--iacgv-python',
            str(executable),
            '--local-trusted',
            '--before',
            BEFORE,
            '--after',
            AFTER,
            '--framework',
            'terraform',
            '--target',
            'CKV_AWS_3=aws_ebs_volume.target',
            '--checkov-executable',
            str(executable),
        ],
    )


@pytest.fixture
def transport(
    monkeypatch: pytest.MonkeyPatch,
) -> Transport:
    """Stub process transport without claiming product semantics.

    Returns:
        Callable: Configure product exit, report bytes and schema process exit.
    """

    def install(code: int, report: str | None = None, schema: int = 0) -> None:  # noqa: WPS430 — bind fixture state
        def process(run: hook.HookRun, _command: list[str], label: str) -> int:  # noqa: WPS430 — isolated subprocess double
            (run.directory / f'{label}.stdout.log').write_text('1.0.2\n')
            if label == 'schema':
                return schema
            if label == 'verification':
                payload = {
                    'schema_version': 'report-v1',
                    'result_kind': 'verification',
                    'exit_code': code,
                    'verdict': {
                        0: 'VERIFIED',
                        1: 'FAILED',
                        3: 'INCONCLUSIVE',
                    }.get(code),
                }
                run.report.write_text(
                    json.dumps(payload) if report is None else report,
                )
                return code
            return 0

        monkeypatch.setattr(hook.HookRun, '_process', process)

    return install


class TestConfiguration:
    """Exercise parsing and exact argument transport."""

    def test_command(self, repair: Namespace, repository: Path) -> None:
        """Preserve literal selectors and resolve paths against Git root."""
        repair.target.append('CKV_AWS_3=name with spaces;$(literal)@a=b.tf')
        report = repository / '.git/report.json'
        command = hook.verification_command(repair, repository, report)
        assert command[:6] == [
            str(repair.iacgv_python),
            '-I',
            '-B',
            '-m',
            'iac_guard_v.cli',
            'verify',
        ]
        assert str(repository / BEFORE) in command
        assert 'CKV_AWS_3=name with spaces;$(literal)@a=b.tf' in command
        assert '--all-baseline-findings' not in command
        assert command[-2:] == [str(report), '--quiet']

    @pytest.mark.parametrize('field', (BEFORE, AFTER))
    def test_missing_snapshot(
        self,
        repair: Namespace,
        repository: Path,
        field: str,
    ) -> None:
        """Reject nonexistent snapshot directories."""
        setattr(repair, field, Path('absent'))
        with pytest.raises(ValueError, match='distinct existing'):
            hook.verification_command(
                repair,
                repository,
                repository / REPORT,
            )

    @pytest.mark.parametrize('field', ('iacgv_python', 'checkov_executable'))
    @pytest.mark.parametrize(
        'alias',
        ('direct', 'file-symlink', 'directory-symlink', 'venv-symlink'),
    )
    def test_candidate_runtime(
        self,
        repair: Namespace,
        repository: Path,
        field: str,
        alias: str,
    ) -> None:
        """Reject a candidate-owned verifier, scanner or Python environment."""
        executable = repository / AFTER / 'bin/python'
        executable.parent.mkdir()
        if alias == 'venv-symlink':
            executable.symlink_to(repair.iacgv_python)
        else:
            executable.write_text('#!/bin/sh\nexit 0\n')
            executable.chmod(hook.PRIVATE_DIRECTORY_MODE)
        selected = executable
        if alias == 'file-symlink':
            selected = repository / 'alias'
            selected.symlink_to(executable)
        elif alias == 'directory-symlink':
            parent = repository / 'alias'
            parent.symlink_to(executable.parent, target_is_directory=True)
            selected = parent / executable.name
        setattr(repair, field, selected)
        assert hook.invoke_cli_app(repair) == hook.INCONCLUSIVE
        assert not (repository / '.git/iac-guard-v').exists()

    def test_same_snapshot(self, repair: Namespace, repository: Path) -> None:
        """Reject a symlink alias of the same snapshot."""
        alias = repository / 'alias'
        alias.symlink_to(repository / BEFORE, target_is_directory=True)
        repair.after = alias
        with pytest.raises(ValueError, match='distinct existing'):
            hook.verification_command(
                repair,
                repository,
                repository / REPORT,
            )

    def test_output_in_snapshot(
        self,
        repair: Namespace,
        repository: Path,
    ) -> None:
        """Do not place reports in protected input trees."""
        with pytest.raises(ValueError, match='outside both'):
            hook.verification_command(
                repair,
                repository,
                repository / 'before/report',
            )

    @pytest.mark.parametrize('path', ('relative', '/absent/runtime'))
    def test_invalid_executable(
        self,
        repair: Namespace,
        repository: Path,
        path: str,
    ) -> None:
        """Require explicit absolute installed executables."""
        repair.iacgv_python = Path(path)
        with pytest.raises(ValueError, match='absolute, executable'):
            hook.verification_command(
                repair,
                repository,
                repository / REPORT,
            )

    @pytest.mark.parametrize(
        'arguments',
        ((), ('--unknown',), ('--bef', 'x'), ('--args=--soft-fail',)),
    )
    def test_invalid_parser(self, arguments: tuple[str, ...]) -> None:
        """Reject missing, abbreviated and unexpected arguments."""
        with pytest.raises(SystemExit) as error:
            _cli.invoke_cli_app(['iac-guard-v', *arguments])
        assert error.value.code == USAGE_ERROR


class TestResults:
    """Require fresh, consistent reports and preserve product errors."""

    @pytest.mark.parametrize('code', (0, 1, 3, 2, 4, 17, -9))
    def test_exit(
        self,
        repair: Namespace,
        transport: Transport,
        code: int,
    ) -> None:
        """Keep errors distinct; a killed child cannot establish success."""
        transport(code)
        expected = hook.INCONCLUSIVE if code < 0 else code
        assert hook.invoke_cli_app(repair) == expected

    @pytest.mark.parametrize(
        REPORT,
        (
            '',
            '{',
            '[]',
            '{}',
            '{"exit_code":true}',
            '{"exit_code":0,"verdict":"FAILED"}',
        ),
    )
    def test_invalid_report(
        self,
        repair: Namespace,
        transport: Transport,
        report: str,
    ) -> None:
        """The released schema must reject malformed or partial output."""
        transport(0, report, 1)
        assert hook.invoke_cli_app(repair) == hook.INCONCLUSIVE

    def test_inconsistent_exit(
        self,
        repair: Namespace,
        transport: Transport,
    ) -> None:
        """Even a schema-valid report must match this process exit."""
        transport(
            0,
            json.dumps(
                {
                    'schema_version': 'report-v1',
                    'result_kind': 'verification',
                    'exit_code': 1,
                    'verdict': 'FAILED',
                },
            ),
        )
        assert hook.invoke_cli_app(repair) == hook.INCONCLUSIVE

    def test_operational_uncertainty(
        self,
        repair: Namespace,
        transport: Transport,
    ) -> None:
        """Keep the released operational uncertainty classification."""
        payload = {
            'schema_version': 'report-v1',
            'result_kind': 'operational_uncertainty',
            'verdict': 'INCONCLUSIVE',
            'exit_code': hook.INCONCLUSIVE,
        }
        transport(hook.INCONCLUSIVE, json.dumps(payload))
        assert hook.invoke_cli_app(repair) == hook.INCONCLUSIVE

    def test_invalid_json_after_validation(
        self,
        repair: Namespace,
        transport: Transport,
    ) -> None:
        """A changed/malformed report cannot fail open after validation."""
        transport(0, '{')
        assert hook.invoke_cli_app(repair) == hook.INCONCLUSIVE

    def test_retention(
        self,
        repair: Namespace,
        repository: Path,
        transport: Transport,
    ) -> None:
        """Repeated and concurrent requests never overwrite evidence."""
        transport(0)
        with ThreadPoolExecutor(max_workers=2) as executor:
            assert list(
                executor.map(hook.invoke_cli_app, (repair, repair)),
            ) == [0, 0]
        reports = list(repository.glob('.git/iac-guard-v/runs/*/report.json'))
        original = {path: path.read_bytes() for path in reports}
        assert len(reports) == REPEATED_RUNS
        assert hook.invoke_cli_app(repair) == 0
        assert all(
            path.read_bytes() == original_bytes
            for path, original_bytes in original.items()
        )

    def test_nested(
        self,
        repair: Namespace,
        repository: Path,
        monkeypatch: pytest.MonkeyPatch,
        transport: Transport,
    ) -> None:
        """Nested callers retain repository-relative snapshot meaning."""
        transport(0)
        monkeypatch.chdir(repository / AFTER)
        assert hook.invoke_cli_app(repair) == 0


class TestErrors:
    """Fail closed on setup, process and filesystem exceptions."""

    @pytest.mark.parametrize(
        'error',
        (
            OSError('blocked'),
            subprocess.TimeoutExpired('verify', 1),
            KeyboardInterrupt(),
        ),
    )
    def test_execution(
        self,
        repair: Namespace,
        monkeypatch: pytest.MonkeyPatch,
        error: BaseException,
    ) -> None:
        """Unsuccessful subprocess execution never returns verified success."""

        def process(*_args: object) -> int:  # noqa: WPS430 — exception injection
            raise error

        monkeypatch.setattr(hook.HookRun, '_process', process)
        assert hook.invoke_cli_app(repair) == hook.INCONCLUSIVE

    def test_missing_git(
        self,
        repair: Namespace,
        monkeypatch: pytest.MonkeyPatch,
    ) -> None:
        """Explain an absent Git runtime without traceback."""
        monkeypatch.setattr(shutil, 'which', lambda _: None)
        assert hook.invoke_cli_app(repair) == hook.INCONCLUSIVE

    def test_symlink_reports(
        self,
        repair: Namespace,
        repository: Path,
    ) -> None:
        """Reject candidate-selected report directory redirection."""
        (repository / '.git/iac-guard-v').symlink_to(
            repository / AFTER,
            target_is_directory=True,
        )
        assert hook.invoke_cli_app(repair) == hook.INCONCLUSIVE
        assert not (repository / 'after/runs').exists()

    def test_missing_report(
        self,
        repair: Namespace,
        monkeypatch: pytest.MonkeyPatch,
    ) -> None:
        """A zero exit with no new report cannot establish a result."""

        def process(run: hook.HookRun, _command: list[str], label: str) -> int:  # noqa: WPS430 — missing report injection
            (run.directory / f'{label}.stdout.log').write_text('1.0.2\n')
            return 0

        monkeypatch.setattr(hook.HookRun, '_process', process)
        assert hook.invoke_cli_app(repair) == hook.INCONCLUSIVE

    def test_no_input_mutation(
        self,
        repair: Namespace,
        repository: Path,
    ) -> None:
        """Reject overlap before creating any report directories."""
        repair.before = repository
        assert hook.invoke_cli_app(repair) == hook.INCONCLUSIVE
        assert not (repository / '.git/iac-guard-v').exists()

    def test_wrong_version(self, repair: Namespace) -> None:
        """An executable without the released product fails before verify."""
        assert hook.invoke_cli_app(repair) == hook.INCONCLUSIVE

    def test_real_process(self, repair: Namespace) -> None:
        """Exercise log creation with literal argv and the real process API."""
        run = hook.HookRun(repair)
        shell = shutil.which('sh')
        assert shell is not None
        assert run._process([shell, '-c', 'exit 4'], 'test') == EXECUTION_ERROR  # noqa: SLF001 — exercise transport boundary
        assert (run.directory / 'test.stderr.log').is_file()
