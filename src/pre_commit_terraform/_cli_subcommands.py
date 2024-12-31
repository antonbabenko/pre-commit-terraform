"""A CLI sub-commands organization module."""

from . import terraform_docs_replace
from . import terraform_checkov
from ._types import CLISubcommandModuleProtocol

SUBCOMMAND_MODULES: list[CLISubcommandModuleProtocol] = [
    terraform_docs_replace,
    terraform_checkov,
]


__all__ = ('SUBCOMMAND_MODULES',)
