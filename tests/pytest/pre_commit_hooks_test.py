"""Tests for hook manifest file-selection patterns."""

import re
from pathlib import Path

import pytest


MANIFEST_PATH = Path(__file__).resolve().parents[2] / '.pre-commit-hooks.yaml'


@pytest.mark.parametrize(
    ('file_name', 'should_match'),
    (
        pytest.param('main.tf', True, id='terraform-hcl'),
        pytest.param('main.tofu', True, id='opentofu-hcl'),
        pytest.param('main.tf.json', True, id='terraform-json'),
        pytest.param('main.tofu.json', True, id='opentofu-json'),
        pytest.param('values.tfvars', True, id='terraform-variables'),
        pytest.param(
            'values.tfvars.json',
            True,
            id='terraform-variables-json',
        ),
        pytest.param('.terraform.lock.hcl', True, id='terraform-lock'),
        pytest.param('README.md', False, id='markdown'),
        pytest.param('main.txt', False, id='text'),
        pytest.param('foo.tofu.json.bak', False, id='opentofu-json-backup'),
        pytest.param('tofu.json', False, id='json-without-tofu-suffix'),
        pytest.param('main.tf.json.tmp', False, id='terraform-json-temporary'),
        pytest.param('arbitrary.json', False, id='arbitrary-json'),
        pytest.param(
            'main.tofuxjson',
            False,
            id='opentofu-wildcard-near-miss',
        ),
        pytest.param(
            'main.tfaxjson',
            False,
            id='terraform-wildcard-near-miss',
        ),
        pytest.param(
            'values.tfvarsxjson',
            False,
            id='terraform-variables-json-near-miss',
        ),
    ),
)
def test_terraform_validate_file_selection(
    file_name: str,
    *,
    should_match: bool,
) -> None:
    """Verify the manifest selects only supported configuration filenames."""
    manifest = MANIFEST_PATH.read_text(encoding='utf-8')
    hook_block = manifest.split('- id: terraform_validate\n', maxsplit=1)[1]
    hook_block = hook_block.split('\n- id: ', maxsplit=1)[0]
    files_line = next(
        line
        for line in hook_block.splitlines()
        if line.startswith('  files: ')
    )
    files_pattern = re.compile(files_line.removeprefix('  files: '))

    assert bool(files_pattern.search(file_name)) is should_match
