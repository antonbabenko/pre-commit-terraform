from pre_commit_terraform import terraform_checkov
from pre_commit_terraform import terraform_docs_replace
from pre_commit_terraform import terraform_fmt
from pre_commit_terraform._cli_subcommands import SUBCOMMAND_MODULES


def test_subcommand_modules(mocker):
    mock_terraform_checkov = mocker.patch('pre_commit_terraform.terraform_checkov')
    mock_terraform_docs_replace = mocker.patch('pre_commit_terraform.terraform_docs_replace')
    mock_terraform_fmt = mocker.patch('pre_commit_terraform.terraform_fmt')

    mock_subcommand_modules = (
        mock_terraform_docs_replace,
        mock_terraform_fmt,
        mock_terraform_checkov,
    )

    mocker.patch(
        'pre_commit_terraform._cli_subcommands.SUBCOMMAND_MODULES',
        mock_subcommand_modules,
    )

    from pre_commit_terraform._cli_subcommands import (
        SUBCOMMAND_MODULES as patched_subcommand_modules,
    )

    assert patched_subcommand_modules == mock_subcommand_modules


def test_subcommand_modules_content():
    assert terraform_docs_replace in SUBCOMMAND_MODULES
    assert terraform_fmt in SUBCOMMAND_MODULES
    assert terraform_checkov in SUBCOMMAND_MODULES
