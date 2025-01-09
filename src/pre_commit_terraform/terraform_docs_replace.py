import os
import subprocess
import warnings
from argparse import ArgumentParser, Namespace
from typing import cast as cast_to

from ._structs import ReturnCode
from ._types import ReturnCodeType


CLI_SUBCOMMAND_NAME: str = 'replace-docs'


def populate_argument_parser(subcommand_parser: ArgumentParser) -> None:
    subcommand_parser.description = (
        'Run terraform-docs on a set of files. Follows the standard '
        'convention of pulling the documentation from main.tf in order to '
        'replace the entire README.md file each time.'
    )
    subcommand_parser.add_argument(
        '--dest', dest='dest', default='README.md',
    )
    subcommand_parser.add_argument(
        '--sort-inputs-by-required', dest='sort', action='store_true',
        help='[deprecated] use --sort-by-required instead',
    )
    subcommand_parser.add_argument(
        '--sort-by-required', dest='sort', action='store_true',
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
    warnings.warn(
        '`terraform_docs_replace` hook is DEPRECATED.'
        'For migration instructions see '
        'https://github.com/antonbabenko/pre-commit-terraform/issues/248'
        '#issuecomment-1290829226',
        category=UserWarning,
    )

    dirs: list[str] = []
    for filename in cast_to(list[str], parsed_cli_args.filenames):
        if (os.path.realpath(filename) not in dirs and
                (filename.endswith(".tf") or filename.endswith(".tfvars"))):
            dirs.append(os.path.dirname(filename))

    retval = ReturnCode.OK

    for dir in dirs:
        try:
            procArgs = []
            procArgs.append('terraform-docs')
            if cast_to(bool, parsed_cli_args.sort):
                procArgs.append('--sort-by-required')
            procArgs.append('md')
            procArgs.append("./{dir}".format(dir=dir))
            procArgs.append('>')
            procArgs.append(
                './{dir}/{dest}'.
                format(dir=dir, dest=cast_to(bool, parsed_cli_args.dest)),
            )
            subprocess.check_call(" ".join(procArgs), shell=True)
        except subprocess.CalledProcessError as e:
            print(e)
            retval = ReturnCode.ERROR
    return retval
