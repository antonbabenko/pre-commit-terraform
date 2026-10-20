#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR

# shellcheck source=_common.sh
. "$SCRIPT_DIR/_common.sh"

#
# Unique part
#

# TODO: virtualenv>=21.14.6 needs packaging>=26.3, but checkov pins packaging<24
# (https://github.com/bridgecrewio/checkov/issues/6950). Drop the pin when checkov relaxes it.
if [[ $VERSION == latest ]]; then
  pip3 install --no-cache-dir "$TOOL" 'virtualenv<21.14.6'
else
  pip3 install --no-cache-dir "${TOOL}==${VERSION}" 'virtualenv<21.14.6'
fi
pip3 check
