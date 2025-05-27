"""Data structures to be reused across the app."""

from enum import IntEnum


class ReturnCode(IntEnum):
    """POSIX-style return code values.

    To be used in check callable implementations.
    """

    OK = 0
    ERROR = 1


__all__ = ('ReturnCode',)
