"""Argument parser initialization logic.

This defines helpers for setting up both the root parser and the parsers
of all the sub-commands.
"""

from argparse import ArgumentParser

from .terraform_docs_replace import (
    populate_argument_parser as populate_replace_docs_argument_parser,
)


PARSER_MAP = {
    'replace-docs': populate_replace_docs_argument_parser,
}


def attach_subcommand_parsers_to(root_cli_parser: ArgumentParser, /) -> None:
    """Connect all sub-command parsers to the given one.

    This functions iterates over a mapping of subcommands to their
    respective population functions, executing them to augment the
    main parser.
    """
    subcommand_parsers = root_cli_parser.add_subparsers(
        dest='check_name',
        help='A check to be performed.',
        required=True,
    )
    for subcommand_name, initialize_subcommand_parser in PARSER_MAP.items():
        replace_docs_parser = subcommand_parsers.add_parser(subcommand_name)
        initialize_subcommand_parser(replace_docs_parser)


def initialize_argument_parser() -> ArgumentParser:
    """Return the root argument parser with sub-commands."""
    root_cli_parser = ArgumentParser(prog=f'python -m {__package__ !s}')
    attach_subcommand_parsers_to(root_cli_parser)
    return root_cli_parser


__all__ = ('initialize_argument_parser',)
