"""Composite types for annotating in-project code."""

from ._structs import ReturnCode


ReturnCodeType = ReturnCode | int
