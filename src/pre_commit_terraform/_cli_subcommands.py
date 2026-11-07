"""A CLI sub-commands organization module."""

from . import terraform_docs_replace, terraform_iac_guard_v
from ._types import CLISubcommandModuleProtocol


SUBCOMMAND_MODULES: tuple[CLISubcommandModuleProtocol, ...] = (
    terraform_docs_replace,
    terraform_iac_guard_v,
)


__all__ = ('SUBCOMMAND_MODULES',)
