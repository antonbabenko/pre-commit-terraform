"""Composite types for annotating in-project code."""

from argparse import ArgumentParser
from argparse import Namespace
from typing import Final
from typing import Protocol

from pre_commit_terraform._structs import ReturnCode

ReturnCodeType = ReturnCode | int


class CLISubcommandModuleProtocol(Protocol):
    """A protocol for the subcommand-implementing module shape."""

    HOOK_ID: Final[str]
    """This constant contains a CLI."""

    def populate_argument_parser(self, subcommand_parser: ArgumentParser) -> None:
        """Run a module hook for populating the subcommand parser."""

    def invoke_cli_app(self, parsed_cli_args: Namespace) -> ReturnCodeType | int:
        """Run a module hook implementing the subcommand logic."""
        ...  # pylint: disable=unnecessary-ellipsis


__all__ = ('CLISubcommandModuleProtocol', 'ReturnCodeType')
