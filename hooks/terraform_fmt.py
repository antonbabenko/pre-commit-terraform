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

logger = logging.getLogger(__name__)


def main(argv: Sequence[str] | None = None) -> int:
    # noqa: DAR101, DAR201 # TODO: Add docstrings when will end up with final implementation
    """
    Execute terraform_fmt_py pre-commit hook.

    Parses args and calls `terraform fmt` on list of files provided by pre-commit.
    """
    common.setup_logging()
    logger.debug(sys.version_info)
    # FIXME: WPS236
    args, hook_config, files, _tf_init_args, env_vars_strs = common.parse_cmdline(argv)  # noqa: WPS236

    all_env_vars = {**os.environ, **common.parse_env_vars(env_vars_strs)}
    expanded_args = common.expand_env_vars(args, all_env_vars)

    if os.environ.get('PRE_COMMIT_COLOR') == 'never':
        args.append('-no-color')

    return common.per_dir_hook(
        hook_config,
        files,
        expanded_args,
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
    quoted_args = [shlex.quote(arg) for arg in args]
    cmd = [tf_path, 'fmt', *quoted_args, dir_path]

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
