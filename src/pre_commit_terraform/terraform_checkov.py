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
from pre_commit_terraform._run_on_whole_repo import is_function_defined
from pre_commit_terraform._run_on_whole_repo import is_hook_run_on_whole_repo
from pre_commit_terraform._types import ReturnCodeType

logger = logging.getLogger(__name__)


def replace_git_working_dir_to_repo_root(args: list[str]) -> list[str]:
    """
    Support for setting PATH to repo root.

    Replace '__GIT_WORKING_DIR__' with the current working directory in each argument.

    Args:
        args: List of arguments to process.

    Returns:
        List of arguments with '__GIT_WORKING_DIR__' replaced.
    """
    return [arg.replace('__GIT_WORKING_DIR__', os.getcwd()) for arg in args]


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
    expanded_args = replace_git_working_dir_to_repo_root(expanded_args)
    # Just in case is someone somehow will add something like "; rm -rf" in the args
    safe_args = [shlex.quote(arg) for arg in expanded_args]

    if os.environ.get('PRE_COMMIT_COLOR') == 'never':
        # TODO: subprocess.run ignore colors. Try `rich` lib
        all_env_vars['ANSI_COLORS_DISABLED'] = 'true'
    # WPS421 - IDK how to check is function exist w/o passing globals()
    if is_function_defined('run_hook_on_whole_repo', globals()):  # noqa: WPS421
        if is_hook_run_on_whole_repo(HOOK_ID, parsed_cli_args.files):
            return run_hook_on_whole_repo(safe_args, all_env_vars)

    return common.per_dir_hook(
        parsed_cli_args.hook_config,
        parsed_cli_args.files,
        safe_args,
        all_env_vars,
        per_dir_hook_unique_part,
    )


def run_hook_on_whole_repo(args: list[str], env_vars: dict[str, str]) -> int:
    """
    Run the hook on the whole repository.

    Args:
        args: The arguments to pass to the hook
        env_vars: All environment variables provided to hook from system and
            defined by user in hook config.

    Returns:
        int: The exit code of the hook.
    """
    cmd = ['checkov', '-d', '.', *args]

    logger.debug(
        'Running hook on the whole repository with values:\nargs: %s \nenv_vars: %r',
        args,
        env_vars,
    )
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


def per_dir_hook_unique_part(
    tf_path: str,  # pylint: disable=unused-argument
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
    cmd = ['checkov', '-d', dir_path, *args]

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
