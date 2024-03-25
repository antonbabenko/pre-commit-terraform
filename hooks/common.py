from __future__ import annotations

import argparse
import logging
import os
from collections.abc import Sequence

logger = logging.getLogger(__name__)


def setup_logging():
    logging.basicConfig(
        level={
            "error": logging.ERROR,
            "warn": logging.WARNING,
            "warning": logging.WARNING,
            "info": logging.INFO,
            "debug": logging.DEBUG,
        }[os.environ.get("PRE_COMMIT_TERRAFORM_LOG_LEVEL", "warning").lower()]
    )


def parse_env_vars(ev_strs: list[str]) -> dict[str, str]:
    ret = {}
    for ev_str in ev_strs:
        name, val = ev_str.split("=", 1)
        if val.startswith('"') and val.endswith('"'):
            val = val[1:-1]
        ret[name] = val
    return ret


def parse_cmdline(
    argv: Sequence[str] | None = None,
) -> tuple[list[str], list[str], list[str], list[str], dict[str, str]]:
    parser = argparse.ArgumentParser(
        add_help=False,  # to allow us to use -h to be compatible with previous bash version
    )
    parser.add_argument("-a", "--args", action="append", help="Arguments")
    parser.add_argument("-h", "--hook-config", action="append", help="Hook Config")
    parser.add_argument("-i", "--init-args", "--tf-init-args", action="append", help="Init Args")
    parser.add_argument("-e", "--envs", "--env-vars", action="append", help="Environment Variables")
    parser.add_argument("FILES", nargs="*", help="Files")

    parsed_args = parser.parse_args(argv)

    args = parsed_args.args or []
    hook_config = parsed_args.hook_config or []
    files = parsed_args.FILES or []
    tc_init_args = parsed_args.init_args or []
    env_vars = parsed_args.envs or []

    env_var_dict = parse_env_vars(env_vars)

    if hook_config:
        raise NotImplementedError("TODO: implement: hook_config")

    if tc_init_args:
        raise NotImplementedError("TODO: implement: tc_init_args")

    return args, hook_config, files, tc_init_args, env_var_dict
