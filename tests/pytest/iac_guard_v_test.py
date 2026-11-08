"""Deterministic transport tests; real product tests run separately."""

# Repeated boundary assertions keep failure scenarios independently legible.
# flake8: noqa: WPS204

from __future__ import annotations

import json
import os
import shutil
import signal
import subprocess
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from types import SimpleNamespace
from typing import TYPE_CHECKING, Final, Protocol, cast

import pytest
from pre_commit_terraform import _cli
from pre_commit_terraform import terraform_iac_guard_v as hook


if TYPE_CHECKING:
    from collections.abc import Callable

    from pre_commit_terraform.terraform_iac_guard_v import _Arguments


BEFORE = 'before'
AFTER = 'after'
REPORT = 'report'
USAGE_ERROR = 2
EXECUTION_ERROR = 4
REPEATED_RUNS = 2
JSON_DUMPS: Final[Callable[[object], str]] = json.dumps


class Transport(Protocol):
    """Typed process-double installer with optional scenario arguments."""

    def __call__(
        self,
        code: int,
        report: str | None = None,
        schema: int = 0,
        version: str = '1.0.4',
    ) -> None:
        """Select product and report outcomes."""
        ...


@pytest.fixture
def transport(
    monkeypatch: pytest.MonkeyPatch,
) -> Transport:
    """Stub process transport without claiming product semantics.

    Returns:
        Callable: Configure product exit, report bytes and schema process exit.
    """

    def install(
        code: int,
        report: str | None = None,
        schema: int = 0,
        version: str = '1.0.4',
    ) -> None:  # noqa: WPS430 — bind fixture state
        def process(run: hook.HookRun, _command: list[str], label: str) -> int:  # noqa: WPS430 — isolated subprocess double
            (run.directory / f'{label}.stdout.log').write_text(version + '\n')
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
                    JSON_DUMPS(payload) if report is None else report,
                )
                return code
            return 0

        monkeypatch.setattr(hook.HookRun, '_process', process)

    return install


class TestConfiguration:
    """Exercise parsing and exact argument transport."""

    def test_command(self, repair: _Arguments, repository: Path) -> None:
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
        repair: _Arguments,
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
        repair: _Arguments,
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

    def test_same_snapshot(self, repair: _Arguments, repository: Path) -> None:
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
        repair: _Arguments,
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
        repair: _Arguments,
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
    @pytest.mark.parametrize('version', ('1.0.4',))
    def test_exit(
        self,
        repair: _Arguments,
        transport: Transport,
        code: int,
        version: str,
    ) -> None:
        """Keep errors distinct; a killed child cannot establish success."""
        transport(code, version=version)
        expected = hook.INCONCLUSIVE if code < 0 else code
        assert hook.invoke_cli_app(repair) == expected

    @pytest.mark.parametrize(
        'version',
        ('1.0.1', '1.0.2', '1.0.3', '1.0.4rc1', '1.0.5', '2.0.0', ''),
    )
    def test_unreviewed_version(
        self,
        repair: _Arguments,
        transport: Transport,
        version: str,
    ) -> None:
        """No version range or prerelease can inherit protocol authority."""
        transport(0, version=version)
        assert hook.invoke_cli_app(repair) == hook.INCONCLUSIVE

    def test_unreviewed_protocol(
        self,
        repair: _Arguments,
        transport: Transport,
    ) -> None:
        """Reject an unreviewed protocol even if schema validation succeeds."""
        transport(
            0,
            JSON_DUMPS(
                {
                    'schema_version': 'report-v2',
                    'result_kind': 'verification',
                    'exit_code': 0,
                    'verdict': 'VERIFIED',
                },
            ),
            version='1.0.4',
        )
        assert hook.invoke_cli_app(repair) == hook.INCONCLUSIVE

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
        repair: _Arguments,
        transport: Transport,
        report: str,
    ) -> None:
        """The released schema must reject malformed or partial output."""
        transport(0, report, 1)
        assert hook.invoke_cli_app(repair) == hook.INCONCLUSIVE

    def test_inconsistent_exit(
        self,
        repair: _Arguments,
        transport: Transport,
    ) -> None:
        """Even a schema-valid report must match this process exit."""
        transport(
            0,
            JSON_DUMPS(
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
        repair: _Arguments,
        transport: Transport,
    ) -> None:
        """Keep the released operational uncertainty classification."""
        payload = {
            'schema_version': 'report-v1',
            'result_kind': 'operational_uncertainty',
            'verdict': 'INCONCLUSIVE',
            'exit_code': hook.INCONCLUSIVE,
        }
        transport(hook.INCONCLUSIVE, JSON_DUMPS(payload))
        assert hook.invoke_cli_app(repair) == hook.INCONCLUSIVE

    def test_invalid_json_after_validation(
        self,
        repair: _Arguments,
        transport: Transport,
    ) -> None:
        """A changed/malformed report cannot fail open after validation."""
        transport(0, '{')
        assert hook.invoke_cli_app(repair) == hook.INCONCLUSIVE

    def test_retention(
        self,
        repair: _Arguments,
        repository: Path,
        transport: Transport,
    ) -> None:
        """Repeated and concurrent requests never overwrite evidence."""
        transport(0)
        with ThreadPoolExecutor(max_workers=2) as executor:
            futures = [
                executor.submit(hook.invoke_cli_app, repair)
                for _ in range(REPEATED_RUNS)
            ]
            assert [future.result() for future in futures] == [0, 0]
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
        repair: _Arguments,
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
        repair: _Arguments,
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
        repair: _Arguments,
        monkeypatch: pytest.MonkeyPatch,
    ) -> None:
        """Explain an absent Git runtime without traceback."""
        monkeypatch.setattr(shutil, 'which', lambda _: None)
        assert hook.invoke_cli_app(repair) == hook.INCONCLUSIVE

    def test_symlink_reports(
        self,
        repair: _Arguments,
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
        repair: _Arguments,
        monkeypatch: pytest.MonkeyPatch,
    ) -> None:
        """A zero exit with no new report cannot establish a result."""

        def process(run: hook.HookRun, _command: list[str], label: str) -> int:  # noqa: WPS430 — missing report injection
            (run.directory / f'{label}.stdout.log').write_text('1.0.4\n')
            return 0

        monkeypatch.setattr(hook.HookRun, '_process', process)
        assert hook.invoke_cli_app(repair) == hook.INCONCLUSIVE

    def test_no_input_mutation(
        self,
        repair: _Arguments,
        repository: Path,
    ) -> None:
        """Reject overlap before creating any report directories."""
        repair.before = repository
        assert hook.invoke_cli_app(repair) == hook.INCONCLUSIVE
        assert not (repository / '.git/iac-guard-v').exists()

    def test_wrong_version(self, repair: _Arguments) -> None:
        """An executable without the released product fails before verify."""
        assert hook.invoke_cli_app(repair) == hook.INCONCLUSIVE


def test_post_wait_cancellation(
    repair: _Arguments,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """A signal arriving as wait returns cannot become success."""
    run = hook.HookRun(repair)

    def completed(_self: _ProcessDouble, **_kwargs: object) -> int:  # noqa: WPS430 — signal/exit race injection
        run.cancelled = True
        return 0

    process = cast('subprocess.Popen[str]', _ProcessDouble([0]))
    monkeypatch.setattr(_ProcessDouble, 'wait', completed)
    with pytest.raises(KeyboardInterrupt):
        run._wait(process, ['fixture'])  # noqa: SLF001 — race boundary


def test_native_windows_rejected(
    repair: _Arguments,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Unsupported native cleanup fails before runtime or scanner startup."""
    run = hook.HookRun(repair)
    monkeypatch.setattr(hook, 'os', SimpleNamespace(name='nt'))
    with pytest.raises(ValueError, match='POSIX'):
        run._process(['unreachable'], 'windows')  # noqa: SLF001 — platform boundary


def test_quarantine_error_is_diagnostic(
    repair: _Arguments,
    monkeypatch: pytest.MonkeyPatch,
    caplog: pytest.LogCaptureFixture,
) -> None:
    """A retention failure cannot replace cancellation with a false success."""
    run = hook.HookRun(repair)
    run.report.write_text('{}')

    def denied(_path: Path, _target: Path) -> Path:  # noqa: WPS430 — filesystem error injection
        message = 'retention blocked'
        raise OSError(message)

    monkeypatch.setattr(Path, 'rename', denied)
    run.invalidate_report()
    assert 'retention blocked' in caplog.text


def test_cancellation_before_allocation(
    repair: _Arguments,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Fail closed on interruption during Git discovery."""

    def interrupted(_self: hook.HookRun, _args: _Arguments) -> None:  # noqa: WPS430 — allocation interruption
        raise KeyboardInterrupt

    monkeypatch.setattr(hook.HookRun, '__init__', interrupted)
    assert hook.invoke_cli_app(repair) == hook.INCONCLUSIVE


def test_cancelled_after_report(
    repair: _Arguments,
    monkeypatch: pytest.MonkeyPatch,
    repository: Path,
) -> None:
    """Reject cancellation after product completion/report creation."""

    def completed(run: hook.HookRun, _args: _Arguments) -> int:  # noqa: WPS430 — finalization race
        run.report.write_text('{"verdict":"VERIFIED","exit_code":0}')
        run.cancelled = True
        return 0

    monkeypatch.setattr(hook.HookRun, 'verify', completed)
    assert hook.invoke_cli_app(repair) == hook.INCONCLUSIVE
    assert not list(repository.glob('.git/iac-guard-v/runs/*/report.json'))
    assert (
        len(
            list(
                repository.glob(
                    '.git/iac-guard-v/runs/*/unaccepted-report.json',
                ),
            ),
        )
        == 1
    )


class _ProcessDouble:
    """Only the Popen ownership contract consumed by this transport."""

    def __init__(self, responses: list[int | BaseException]) -> None:
        self.responses = responses
        self.pid = 12345
        self.returncode: int | None = None
        self.terminated = False

    def terminate(self) -> None:
        self.terminated = True

    def wait(self, *, timeout: float) -> int:
        outcome = self.responses.pop(0)
        if isinstance(outcome, BaseException):
            raise outcome
        self.returncode = outcome
        return outcome


class _ProcessPlatform:
    """Precisely typed POSIX operations, without sending real OS signals."""

    name = 'posix'

    def __init__(self, signals: list[tuple[int, int]]) -> None:
        self.environ = dict(os.environ)
        self.signals = signals

    def killpg(self, pid: int, signum: int) -> None:
        self.signals.append((pid, signum))


@pytest.mark.parametrize(
    'mode',
    ('completed', 'cancelled', 'deadline', 'escalation'),
)
def test_process_contract(
    repair: _Arguments,
    monkeypatch: pytest.MonkeyPatch,
    mode: str,
) -> None:
    """Test transport exits and bounded cleanup on every unit-test platform."""
    run = hook.HookRun(repair)
    timeout = subprocess.TimeoutExpired('fixture', 1)
    responses: list[int | BaseException] = [EXECUTION_ERROR]
    if mode == 'completed':
        responses = [timeout, EXECUTION_ERROR]
    elif mode == 'escalation':
        responses = [timeout, -9]
    process = _ProcessDouble(responses)
    signals: list[tuple[int, int]] = []
    monkeypatch.setattr(hook, 'signal', SimpleNamespace(SIGKILL=9))
    monkeypatch.setattr(hook, 'os', _ProcessPlatform(signals))

    def spawn(command: list[str], **options: object) -> _ProcessDouble:  # noqa: WPS430 — trusted argv/session transport contract
        assert command == ['literal']
        assert options['start_new_session'] is True
        assert options['cwd'] == run.root
        return process

    monkeypatch.setattr(subprocess, 'Popen', spawn)
    expected: type[BaseException]
    if mode == 'completed':
        assert run._process(['literal'], 'completed') == EXECUTION_ERROR  # noqa: SLF001 — transport contract
        assert (run.directory / 'completed.stderr.log').is_file()
    else:
        if mode == 'deadline':
            monkeypatch.setattr(hook, 'TIMEOUT', 0)
            expected = subprocess.TimeoutExpired
        else:
            run._interrupt(signal.SIGTERM, None)  # noqa: SLF001 — signal latch contract
            expected = KeyboardInterrupt
        with pytest.raises(expected):
            run._process(['literal'], mode)  # noqa: SLF001 — cleanup ownership contract
        assert process.terminated
        assert signals == ([(process.pid, 9)] if mode == 'escalation' else [])
