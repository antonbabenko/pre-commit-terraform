#!/usr/bin/env ash
# shellcheck shell=dash

set -euo pipefail

PCT_ASSET_INCLUDE_VERSION="${PCT_ASSET_INCLUDE_VERSION:-true}"
PCT_SUFFIX="${PCT_SUFFIX:-}"
PCT_ASSET_BIN_NAME="${PCT_ASSET_BIN_NAME:-${PCT_BIN_NAME}}"
PCT_VERSION_PARAM="${PCT_VERSION_PARAM:-"--version"}"

if [ "${PCT_VERSION}" = "latest" ]; then
  PCT_TAG="$(curl -sSfL "https://api.github.com/repos/${PCT_GITHUB_USER}/${PCT_GITHUB_PROJECT}/releases/latest" | jq -r '.tag_name')"
  PCT_VERSION=$(echo "${PCT_TAG}" | grep -o -E -m 1 "[0-9.]+")
else
  PCT_TAG="${PCT_TAG_PREFIX:-v}${PCT_VERSION}"
fi

if [ "${PCT_ASSET_INCLUDE_VERSION}" = "false" ]; then
  PCT_VERSION=""
fi

PCT_GITHUB_URL="https://github.com/${PCT_GITHUB_USER}/${PCT_GITHUB_PROJECT}/releases/download/${PCT_TAG}/${PCT_PREFIX}${PCT_VERSION}${PCT_INFIX}${PCT_ARCH}${PCT_SUFFIX}"

echo Downloading...
curl -sSfL "${PCT_GITHUB_URL}" > "${PCT_BIN_NAME}${PCT_SUFFIX}"
echo Downloaded

case "$PCT_SUFFIX" in
  .zip)
    unzip -q "${PCT_BIN_NAME}${PCT_SUFFIX}" "${PCT_ASSET_BIN_NAME}"
    rm "${PCT_BIN_NAME}${PCT_SUFFIX}"
    ;;
  .tgz | .tar.gz)
    tar -xzf "${PCT_BIN_NAME}${PCT_SUFFIX}" "${PCT_ASSET_BIN_NAME}"
    rm "${PCT_BIN_NAME}${PCT_SUFFIX}"
    ;;
esac

chmod a+x "${PCT_ASSET_BIN_NAME}"
mv "${PCT_ASSET_BIN_NAME}" "${VIRTUAL_ENV}/bin/${PCT_BIN_NAME}"

"${PCT_BIN_NAME}" "${PCT_VERSION_PARAM}"
