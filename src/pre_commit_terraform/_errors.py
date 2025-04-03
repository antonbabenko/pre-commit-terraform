"""App-specific exceptions."""


class PreCommitTerraformBaseError(Exception):
    """Base exception for all the in-app errors."""


class PreCommitTerraformRuntimeError(
    PreCommitTerraformBaseError,
    RuntimeError,
):
    """An exception representing a runtime error condition."""


# N818 - The name mimics the built-in SystemExit and is meant to have exactly
# the same semantics. For this reason, it shouldn't have Error in the name to
# maintain resemblance.
class PreCommitTerraformExit(PreCommitTerraformBaseError, SystemExit):  # noqa: N818
    """An exception for terminating execution from deep app layers."""
