#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
# shellcheck source=_common.sh
. "$SCRIPT_DIR/_common.sh"

# PyPI product: build-time only, never common::resolve_tool_path/runtime install.
# Run in the FINAL image: the controlled launcher binds the relocated Checkov
# executable and its actual interpreter/dependencies. Never modify that install.
if ! command -v checkov > /dev/null; then
  echo 'IaC-Guard-V repair verification requires CHECKOV_VERSION; no scanner installed.' >&2
  exit 1
fi

readonly PRODUCT_ENV=/opt/iac-guard-v
export PYTHONDONTWRITEBYTECODE=1
python3 -m venv --copies --without-pip --system-site-packages "$PRODUCT_ENV"
product_requirement="$TOOL"
if [[ $VERSION != latest ]]; then
  product_requirement="${TOOL}==${VERSION}"
fi
python3 -m pip --python "$PRODUCT_ENV/bin/python" install \
  --no-cache-dir --no-compile "$product_requirement"

# Product integrity requires bytecode-free parser copies. Use the versions of
# shared parser dependencies already selected by Checkov, rather than replacing
# global packages or copying a second scanner tree. python-hcl2 is product-local.
python3 -c 'from importlib.metadata import version; import sys; sys.stdout.write("\n".join(name+"=="+version(name) for name in ("PyYAML", "lark", "regex", "packaging"))+"\n")' > "$PRODUCT_ENV/parser-requirements.txt"
python3 -m pip --python "$PRODUCT_ENV/bin/python" install \
  --no-cache-dir --no-compile --ignore-installed --no-deps \
  -r "$PRODUCT_ENV/parser-requirements.txt"
python3 -m pip --python "$PRODUCT_ENV/bin/python" check
"$PRODUCT_ENV/bin/python" -IBm iac_guard_v.external_checkov \
  --checkov "$(command -v checkov)" --destination "$PRODUCT_ENV/scanner"
# Operator-owned installed files must also be readable by Docker USERID users.
chmod 755 "$PRODUCT_ENV/scanner"

# Installation/provenance validation above is separate from request authority.
# Unknown CHECKOV_VERSION/latest stays installed for ordinary hooks; the product
# rejects unqualified versions/properties when verification is requested.
