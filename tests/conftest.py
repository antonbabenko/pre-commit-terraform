"""Shared consumer fixtures for deterministic and opt-in process tests."""

# Standalone test namespace, matching the existing acceptance runner.
# ruff: noqa: INP001

from __future__ import annotations

import shutil
import subprocess
import sys
from argparse import ArgumentParser
from typing import TYPE_CHECKING

import pytest

from pre_commit_terraform import terraform_iac_guard_v as hook
from pre_commit_terraform.terraform_iac_guard_v import _Arguments


if TYPE_CHECKING:
    from pathlib import Path


BEFORE = 'before'
AFTER = 'after'


@pytest.fixture
def repository(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Path:
    """Create a disposable repository, retaining spaces in its path.

    Returns:
        Path: Repository root.
    """
    # Windows strips trailing spaces from directory names; POSIX retains them.
    name = (
        'repo with spaces' if sys.platform == 'win32' else 'repo with spaces '
    )
    root = tmp_path / name
    root.mkdir()
    git = shutil.which('git')
    assert git is not None
    subprocess.run([git, 'init', '-q', str(root)], check=True)  # noqa: S603 — resolved executable and fixed argv
    monkeypatch.chdir(root)
    return root


@pytest.fixture
def repair(repository: Path) -> _Arguments:
    """Parse a benign explicit repair request.

    Returns:
        _Arguments: Parsed operator-controlled arguments.
    """
    executable = repository / 'python'
    executable.write_text('#!/bin/sh\nexit 0\n')
    executable.chmod(hook.PRIVATE_DIRECTORY_MODE)
    for name in (BEFORE, AFTER):
        (repository / name).mkdir()
    parser = ArgumentParser()
    hook.populate_argument_parser(parser)
    parsed = _Arguments()
    parser.parse_args(
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
        namespace=parsed,
    )
    return parsed
