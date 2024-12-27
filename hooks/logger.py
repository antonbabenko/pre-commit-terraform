"""Here located logs-related functions."""

import logging
import os
from copy import copy


class ColoredFormatter(logging.Formatter):
    """A logging formatter that adds color to the log messages."""

    def __init__(self, pattern: str) -> None:
        """
        Initialize the formatter with the given pattern.

        Args:
            pattern (str): The log message format pattern.
        """
        super().__init__(pattern)
        self.disable_color = os.environ.get('PRE_COMMIT_COLOR') == 'never'

    def format(self, record: logging.LogRecord) -> str:
        """
        Format the log record and add color to the levelname.

        Args:
            record (logging.LogRecord): The log record to format.

        Returns:
            str: The formatted log message.
        """
        if self.disable_color:
            return super().format(record)

        color_mapping = {
            'DEBUG': 37,  # white
            'INFO': 36,  # cyan
            'WARNING': 33,  # yellow
            'ERROR': 31,  # red
            'CRITICAL': 41,  # white on red background
        }

        prefix = '\033['
        suffix = '\033[0m'

        colored_record = copy(record)
        levelname = colored_record.levelname
        seq = color_mapping.get(levelname, 37)  # default white   # noqa: WPS432
        colored_levelname = f'{prefix}{seq}m{levelname}{suffix}'
        colored_record.levelname = colored_levelname

        return super().format(colored_record)


def setup_logging() -> None:
    """
    Set up the logging configuration based on the value of the 'PCT_LOG' environment variable.

    The 'PCT_LOG' environment variable determines the logging level to be used.
    The available levels are:
    - 'error': Only log error messages.
    - 'warn' or 'warning': Log warning messages and above.
    - 'info': Log informational messages and above.
    - 'debug': Log debug messages and above.

    If the 'PCT_LOG' environment variable is not set or has an invalid value,
    the default logging level is 'warning'.
    """
    log_level = {
        'error': logging.ERROR,
        'warn': logging.WARNING,
        'warning': logging.WARNING,
        'info': logging.INFO,
        'debug': logging.DEBUG,
    }[os.environ.get('PCT_LOG', 'warning').lower()]

    log_format = '%(levelname)s:%(funcName)s:%(message)s'
    if log_level == logging.DEBUG:
        log_format = (
            '\n%(levelname)s:\t%(asctime)s.%(msecs)03d %(filename)s:%(lineno)s -> %(funcName)s()'
            + '\n%(message)s'
        )

    formatter = ColoredFormatter(log_format)
    log_handler = logging.StreamHandler()
    log_handler.setFormatter(formatter)

    log = logging.getLogger()
    log.setLevel(log_level)
    log.addHandler(log_handler)
