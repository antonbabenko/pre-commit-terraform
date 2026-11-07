"""Opt-in acceptance tests with provisioned, released runtimes.

Run this file directly, not as part of the deterministic unit suite. Required
operator environment variables: IACGV_TEST_PRODUCT, IACGV_TEST_SCANNER,
IACGV_TEST_HOOK_REPO (a committed checkout), IACGV_TEST_PRE_COMMIT and
IACGV_TEST_DIRECTORY (new evidence directory). No dependencies are installed
by this test. pre-commit provisions its ordinary adapter environment.
"""

# Standalone unittest runner; deliberately outside the pytest unit namespace.
# ruff: noqa: INP001, PT009

from __future__ import annotations

import json
import os
import subprocess
import unittest
from pathlib import Path


BAD = (
    'resource "aws_ebs_volume" "target" {\n'
    '  availability_zone = "us-east-1a"\n'
    '  size = 1\n'
    '  encrypted = false\n}\n'
)
TARGET = 'CKV_AWS_3=aws_ebs_volume.target'
TIMEOUT = 900
GIT = 'git'
AFTER = 'after'


class ReleasedProductTests(unittest.TestCase):
    """Real scanner verdicts and real pre-commit process exits."""

    def setUp(self) -> None:
        """Create a fresh consumer per test and preserve all evidence."""
        self.product = os.environ['IACGV_TEST_PRODUCT']
        self.scanner = os.environ['IACGV_TEST_SCANNER']
        self.precommit = os.environ['IACGV_TEST_PRE_COMMIT']
        self.source = Path(os.environ['IACGV_TEST_HOOK_REPO'])
        self.directory = Path(os.environ['IACGV_TEST_DIRECTORY']) / self.id()
        self.directory.mkdir(parents=True, exist_ok=False)
        self.root = self.directory / 'consumer with spaces; $literal [test]'
        self.root.mkdir()
        # CWD content must not shadow the isolated adapter/product imports.
        (self.root / 'json.py').write_text(
            'raise RuntimeError("cwd import")\n',
        )
        self._environment = dict(
            os.environ,
            PYTHONDONTWRITEBYTECODE='1',
            PRE_COMMIT_HOME=str(self.directory.parent / 'precommit-cache'),
        )
        self._sequence = 0
        self.command([GIT, 'init', '-q'])
        for name, source in (
            ('before', BAD),
            (AFTER, BAD.replace('false', 'true')),
            ('unchanged', f'{BAD}# changed snapshot; same defect\n'),
            ('deleted', 'locals { harmless = true }\n'),
            ('duplicate', BAD + BAD),
            ('malformed', 'resource { !!!'),
            (
                'wrong-resource',
                BAD
                + BAD.replace('"target"', '"other"').replace('false', 'true'),
            ),
            (
                'suppressed',
                BAD.replace(
                    '  size',
                    '  # checkov:skip=CKV_AWS_3:negative control\n  size',
                ),
            ),
        ):
            path = self.root / name
            path.mkdir()
            (path / 'main.tf').write_text(source)
        (self.root / 'after/second.tf').write_text(
            'locals { multiple = true }\n',
        )

    def command(
        self,
        arguments: list[str],
        cwd: Path | None = None,
    ) -> subprocess.CompletedProcess[str]:
        """Retain literal test argv output and process status.

        Returns:
            CompletedProcess: Observed process result.
        """
        self._sequence += 1
        completed = subprocess.run(  # noqa: S603 — explicit test commands, no shell
            arguments,
            cwd=cwd or self.root,
            env=self._environment,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
            timeout=TIMEOUT,
        )
        (self.directory / f'{self._sequence}.log').write_text(completed.stdout)
        return completed

    def test_repair_verdicts(self) -> None:  # noqa: WPS210 — explicit evidence per case
        """Require real fail/pass evidence and reject negative controls."""
        for after, target, expected in (
            (AFTER, TARGET, 0),
            ('unchanged', TARGET, 1),
            ('wrong-resource', TARGET, None),
            ('deleted', TARGET, None),
            ('duplicate', TARGET, None),
            ('malformed', TARGET, None),
            ('suppressed', TARGET, None),
            (AFTER, 'CKV_AWS_3=aws_ebs_volume.absent', None),
            (AFTER, 'CKV_AWS_19=aws_ebs_volume.target', None),
        ):
            with self.subTest(after=after, target=target):
                report = self.directory / f'report-{self._sequence}.json'
                completed = self.command(
                    [
                        self.product,
                        '-IBm',
                        'iac_guard_v.cli',
                        'verify',
                        '--before',
                        str(self.root / 'before'),
                        '--after',
                        str(self.root / after),
                        '--framework',
                        'terraform',
                        '--local-trusted',
                        '--checkov-executable',
                        self.scanner,
                        '--target',
                        target,
                        '--format',
                        'json',
                        '--output',
                        str(report),
                        '--quiet',
                    ],
                )
                payload = json.loads(
                    report.read_text()
                    if report.exists()
                    else completed.stdout,
                )
                self.assertEqual(completed.returncode, payload['exit_code'])
                if expected is None:
                    self.assertNotEqual(completed.returncode, 0)
                    self.assertNotEqual(payload.get('verdict'), 'VERIFIED')
                else:
                    self.assertEqual(completed.returncode, expected)
                    self.assertEqual(
                        payload['verdict'],
                        {0: 'VERIFIED', 1: 'FAILED', 3: 'INCONCLUSIVE'}[
                            expected
                        ],
                    )

    def test_precommit(self) -> None:  # noqa: WPS210 — retain request, reports and process evidence
        """Exercise manifest metadata and different pre-commit selections."""
        revision = self.command(
            [GIT, '-C', str(self.source), 'rev-parse', 'HEAD'],
        ).stdout.strip()
        arguments = [
            f'--iacgv-python={self.product}',
            '--local-trusted',
            '--before=before',
            '--after=after',
            '--framework=terraform',
            f'--target={TARGET}',
            f'--checkov-executable={self.scanner}',
        ]
        config = {
            'repos': [
                {
                    'repo': str(self.source),
                    'rev': revision,
                    'hooks': [
                        {
                            'id': 'terraform_iac_guard_v',
                            'args': arguments,
                        },
                    ],
                },
            ],
        }
        (self.root / '.pre-commit-config.yaml').write_text(json.dumps(config))
        self.command([GIT, 'add', '.'])
        for files in (
            ['.pre-commit-config.yaml'],
            ['after/main.tf', 'after/second.tf'],
            [],
        ):
            with self.subTest(files=files):
                reports = self.root / '.git/iac-guard-v/runs'
                before = set(reports.glob('run-*'))
                completed = self.command(
                    [
                        self.precommit,
                        'run',
                        'terraform_iac_guard_v',
                        '--verbose',
                        '--files',
                        *files,
                    ],
                    cwd=self.root / AFTER,
                )
                self.assertEqual(completed.returncode, 0, completed.stdout)
                fresh = set(reports.glob('run-*')) - before
                self.assertEqual(len(fresh), 1)
        arguments[arguments.index('--after=after')] = '--after=unchanged'
        (self.root / '.pre-commit-config.yaml').write_text(json.dumps(config))
        self.command([GIT, 'add', '.'])
        failed = self.command(
            [self.precommit, 'run', 'terraform_iac_guard_v', '--all-files'],
        )
        self.assertEqual(failed.returncode, 1, failed.stdout)


if __name__ == '__main__':
    unittest.main()
