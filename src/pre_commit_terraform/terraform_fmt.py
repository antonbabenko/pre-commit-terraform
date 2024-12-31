"""Pre-commit hook for terraform fmt."""

from __future__ import annotations

import logging
import os
import shlex
import sys
from argparse import ArgumentParser
from argparse import Namespace
from subprocess import PIPE
from subprocess import run
from typing import Final

from pre_commit_terraform import _common as common
from pre_commit_terraform._logger import setup_logging
from pre_commit_terraform._types import ReturnCodeType

logger = logging.getLogger(__name__)


HOOK_ID: Final[str] = __name__.rpartition('.')[-1] + '_py'  # noqa: WPS336


# pylint: disable=unused-argument
def populate_hook_specific_argument_parser(subcommand_parser: ArgumentParser) -> None:
    """
    Populate the argument parser with the hook-specific arguments.

    Args:
        subcommand_parser: The argument parser to populate.
    """


def invoke_cli_app(parsed_cli_args: Namespace) -> ReturnCodeType:
    """
    Execute main pre-commit hook logic.

    Args:
        parsed_cli_args: Parsed arguments from CLI.

    Returns:
        int: The exit code of the hook.
    """
    setup_logging()
    logger.debug(sys.version_info)

    all_env_vars = {**os.environ, **common.parse_env_vars(parsed_cli_args.env_vars)}
    expanded_args = common.expand_env_vars(parsed_cli_args.args, all_env_vars)
    # Just in case is someone somehow will add something like "; rm -rf" in the args
    safe_args = [shlex.quote(arg) for arg in expanded_args]

    if os.environ.get('PRE_COMMIT_COLOR') == 'never':
        safe_args.append('-no-color')

    return common.per_dir_hook(
        parsed_cli_args.hook_config,
        parsed_cli_args.files,
        safe_args,
        all_env_vars,
        per_dir_hook_unique_part,
    )


def per_dir_hook_unique_part(
    tf_path: str,
    dir_path: str,
    args: list[str],
    env_vars: dict[str, str],
) -> int:
    """
    Run the hook against a single directory.

    Args:
        tf_path: The path to the terraform binary.
        dir_path: The directory to run the hook against.
        args: The arguments to pass to the hook
        env_vars: All environment variables provided to hook from system and
            defined by user in hook config.

    Returns:
        int: The exit code of the hook.
    """
    # Just in case is someone somehow will add something like "; rm -rf" in the args
    cmd = [tf_path, 'fmt', *args, dir_path]

    logger.info('calling %s', shlex.join(cmd))

    completed_process = run(
        cmd,
        env=env_vars,
        text=True,
        stdout=PIPE,
        check=False,
    )

    if completed_process.stdout:
        sys.stdout.write(completed_process.stdout)

    return completed_process.returncode
