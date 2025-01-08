"""Composite types for annotating in-project code."""

from argparse import ArgumentParser
from argparse import Namespace
from collections.abc import Callable
from typing import Protocol
from typing import Union

from pre_commit_terraform._structs import ReturnCode

ReturnCodeType = Union[ReturnCode, int]  # Union instead of pipe for Python 3.9
CLIAppEntryPointCallableType = Callable[[Namespace], ReturnCodeType]


@runtime_checkable
class CLISubcommandModuleProtocol(Protocol):
    """A protocol for the subcommand-implementing module shape."""

    HOOK_ID: str
    """This constant contains a CLI."""

    def populate_argument_parser(self, subcommand_parser: ArgumentParser) -> None:
        """Run a module hook for populating the subcommand parser."""

    def invoke_cli_app(self, parsed_cli_args: Namespace) -> ReturnCodeType:
        """Run a module hook implementing the subcommand logic."""
        ...  # pylint: disable=unnecessary-ellipsis


__all__ = ('CLISubcommandModuleProtocol', 'ReturnCodeType')
