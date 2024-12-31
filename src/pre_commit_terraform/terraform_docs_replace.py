"""Deprecated hook. Don't use it."""

import os
import subprocess
import warnings
from argparse import ArgumentParser
from argparse import Namespace
from typing import Final

from pre_commit_terraform._structs import ReturnCode
from pre_commit_terraform._types import ReturnCodeType

HOOK_ID: Final[str] = __name__.rpartition('.')[-1]


def populate_hook_specific_argument_parser(subcommand_parser: ArgumentParser) -> None:
    """
    Populate the argument parser with the hook-specific arguments.

    Args:
        subcommand_parser: The argument parser to populate.
    """

    subcommand_parser.description = (
        'Run terraform-docs on a set of files. Follows the standard '
        'convention of pulling the documentation from main.tf in order to '
        'replace the entire README.md file each time.'
    )
    subcommand_parser.add_argument(
        '--dest',
        dest='dest',
        default='README.md',
    )
    subcommand_parser.add_argument(
        '--sort-inputs-by-required',
        dest='sort',
        action='store_true',
        help='[deprecated] use --sort-by-required instead',
    )
    subcommand_parser.add_argument(
        '--sort-by-required',
        dest='sort',
        action='store_true',
    )
    subcommand_parser.add_argument(
        '--with-aggregate-type-defaults',
        dest='aggregate',
        action='store_true',
        help='[deprecated]',
    )
    subcommand_parser.add_argument(
        'filenames',
        nargs='*',
        help='Filenames to check.',
    )


def invoke_cli_app(parsed_cli_args: Namespace) -> ReturnCodeType:
    """
    Execute main pre-commit hook logic.

    Args:
        parsed_cli_args: Parsed arguments from CLI.

    Returns:
        int: The exit code of the hook.
    """

    warnings.warn(
        '`terraform_docs_replace` hook is DEPRECATED.'
        + 'For migration instructions see '
        + 'https://github.com/antonbabenko/pre-commit-terraform/issues/248'
        + '#issuecomment-1290829226',
        category=UserWarning,
    )

    dirs = []
    for filename in parsed_cli_args.filenames:
        if os.path.realpath(filename) not in dirs and (
            filename.endswith('.tf') or filename.endswith('.tfvars')
        ):
            dirs.append(os.path.dirname(filename))

    retval = ReturnCode.OK

    for directory in dirs:
        try:
            proc_args = []
            proc_args.append('terraform-docs')
            if parsed_cli_args.sort:
                proc_args.append('--sort-by-required')
            proc_args.append('md')
            proc_args.append(f'./{directory}')
            proc_args.append('>')
            proc_args.append(f'./{directory}/{parsed_cli_args.dest}')
            subprocess.check_call(' '.join(proc_args), shell=True)
        except subprocess.CalledProcessError as exception:
            print(exception)
            retval = ReturnCode.ERROR
    return retval
