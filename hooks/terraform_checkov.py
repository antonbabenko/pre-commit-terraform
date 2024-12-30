"""Pre-commit hook for terraform fmt."""

from __future__ import annotations

import logging
import os
import shlex
import sys
from subprocess import PIPE
from subprocess import run
from typing import Sequence

from . import common
from .logger import setup_logging

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


def main(argv: Sequence[str] | None = None) -> int:
    # noqa: DAR101, DAR201 # TODO: Add docstrings when will end up with final implementation
    """
    Execute terraform_fmt_py pre-commit hook.

    Parses args and calls `terraform fmt` on list of files provided by pre-commit.
    """
    setup_logging()
    logger.debug(sys.version_info)

    args, hook_config, files, _tf_init_args, env_vars_strs = common.parse_cmdline(argv)

    all_env_vars = {**os.environ, **common.parse_env_vars(env_vars_strs)}
    expanded_args = common.expand_env_vars(args, all_env_vars)
    expanded_args = replace_git_working_dir_to_repo_root(expanded_args)
    # Just in case is someone somehow will add something like "; rm -rf" in the args
    safe_args = [shlex.quote(arg) for arg in expanded_args]

    if os.environ.get('PRE_COMMIT_COLOR') == 'never':
        all_env_vars['ANSI_COLORS_DISABLED'] = 'true'  # TODO: Check is it works as expected
    # WPS421 - IDK how to check is function exist w/o passing globals()
    if common.is_function_defined('run_hook_on_whole_repo', globals()):  # noqa: WPS421
        if common.is_hook_run_on_whole_repo(files):
            return run_hook_on_whole_repo(safe_args, all_env_vars)

    return common.per_dir_hook(
        hook_config,
        files,
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


if __name__ == '__main__':
    raise SystemExit(main())
