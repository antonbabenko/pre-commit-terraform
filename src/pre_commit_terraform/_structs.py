"""Data structures to be reused across the app."""

from enum import IntEnum


class ReturnCode(IntEnum):
    """POSIX-style return code values.

    To be used in check callable implementations.
    """

    # WPS115: "Require snake_case for naming class attributes". According to
    # "Correct" example in docs - it's valid use case => false-positive
    OK = 0  # noqa: WPS115
    ERROR = 1  # noqa: WPS115


__all__ = ('ReturnCode',)
