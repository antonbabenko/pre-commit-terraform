"""A CLI sub-commands organization module."""

from . import terraform_docs_replace
from ._types import CLISubcommandModuleProtocol


SUBCOMMAND_MODULES: list[CLISubcommandModuleProtocol] = [
    terraform_docs_replace,
]


__all__ = ('SUBCOMMAND_MODULES',)
