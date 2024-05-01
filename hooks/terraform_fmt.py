"""
Pre-commit hook for terraform fmt.
"""
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


def main(argv: Sequence[str] | None = None) -> int:
    """
    Main entry point for terraform_fmt_py pre-commit hook.
    Parses args and calls `terraform fmt` on list of files provided by pre-commit.
    """

    setup_logging()

    logger.debug(sys.version_info)

    args, _hook_config, files, _tf_init_args, env_vars = parse_cmdline(argv)

    if os.environ.get('PRE_COMMIT_COLOR') == 'never':
        args.append('-no-color')

    cmd = ['terraform', 'fmt', *args, *files]

    logger.info('calling %s', shlex.join(cmd))
    logger.debug('env_vars: %r', env_vars)
    logger.debug('args: %r', args)

    completed_process = run(
        cmd, env={**os.environ, **env_vars},
        text=True, stdout=PIPE, check=False,
    )

    if completed_process.stdout:
        print(completed_process.stdout)

    return completed_process.returncode


if __name__ == '__main__':
    raise SystemExit(main())
