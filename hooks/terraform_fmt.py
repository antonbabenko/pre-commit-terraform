"""Pre-commit hook for terraform fmt."""

from __future__ import annotations

import logging
import os
import shlex
import sys
from subprocess import PIPE
from subprocess import run
from typing import Sequence

from .common import parse_cmdline
from .common import setup_logging

logger = logging.getLogger(__name__)


def get_unique_dirs(files: list[str]) -> set[str]:
    """
    Get unique directories from a list of files.

    Args:
        files: list of file paths.

    Returns:
        Set of unique directories.
    """
    unique_dirs = set()

    for file_path in files:
        dir_path = os.path.dirname(file_path)
        unique_dirs.add(dir_path)

    return unique_dirs


def main(argv: Sequence[str] | None = None) -> int:
    # noqa: DAR101, DAR201 # TODO: Add docstrings when will end up with final implementation
    """
    Execute terraform_fmt_py pre-commit hook.

    Parses args and calls `terraform fmt` on list of files provided by pre-commit.
    """
    setup_logging()

    logger.debug(sys.version_info)

    args, _hook_config, files, _tf_init_args, env_vars = parse_cmdline(argv)

    if os.environ.get('PRE_COMMIT_COLOR') == 'never':
        args.append('-no-color')

    # TODO: Per-dir execution
    # consume modified files passed from pre-commit so that
    # hook runs against only those relevant directories
    unique_dirs = get_unique_dirs(files)

    final_exit_code = 0
    for dir_path in unique_dirs:
        # TODO: per_dir_hook_unique_part call here
        exit_code = per_dir_hook_unique_part(dir_path, args, env_vars)

        if exit_code != 0:
            final_exit_code = exit_code

    return final_exit_code


def per_dir_hook_unique_part(dir_path: str, args: list[str], env_vars: dict[str, str]) -> int:
    """
    Run the hook against a single directory.

    Args:
        dir_path: The directory to run the hook against.
        args: The arguments to pass to the hook
        env_vars: The environment variables to pass to the hook

    Returns:
        int: The exit code of the hook.
    """
    cmd = ['terraform', 'fmt', *args, dir_path]

    logger.info('calling %s', shlex.join(cmd))
    logger.debug('env_vars: %r', env_vars)
    logger.debug('args: %r', args)

    completed_process = run(
        cmd,
        env={**os.environ, **env_vars},
        text=True,
        stdout=PIPE,
        check=False,
    )

    if completed_process.stdout:
        sys.stdout.write(completed_process.stdout)

    return completed_process.returncode


if __name__ == '__main__':
    raise SystemExit(main())
