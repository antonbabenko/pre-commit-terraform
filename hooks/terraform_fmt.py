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
from .common import per_dir_hook
from .common import setup_logging

logger = logging.getLogger(__name__)


def main(argv: Sequence[str] | None = None) -> int:
    # noqa: DAR101, DAR201 # TODO: Add docstrings when will end up with final implementation
    """
    Execute terraform_fmt_py pre-commit hook.

    Parses args and calls `terraform fmt` on list of files provided by pre-commit.
    """
    setup_logging()
    logger.debug(sys.version_info)

    args, _hook_config, files, _tf_init_args, env_vars = parse_cmdline(argv)  # noqa: WPS236 # FIXME

    if os.environ.get('PRE_COMMIT_COLOR') == 'never':
        args.append('-no-color')

    return per_dir_hook(files, args, env_vars, per_dir_hook_unique_part)


def per_dir_hook_unique_part(dir_path: str, args: list[str], env_vars: dict[str, str]) -> int:
    """
    Run the hook against a single directory.

    Args:
        dir_path: The directory to run the hook against.
        args: The arguments to pass to the hook
        env_vars: The custom environment variables defined by user in hook config.

    Returns:
        int: The exit code of the hook.
    """
    # Just in case is someone somehow will add something like "; rm -rf" in the args
    quoted_args = [shlex.quote(arg) for arg in args]
    cmd = ['terraform', 'fmt', *quoted_args, dir_path]

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
