#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

TAG_NAME="$1"
DIST_DIR="$2"
PUBLISH_BRANCH="$3"
REPO="$4"

if [[ -z "${REPO}" ]]; then
  REPO="${GITHUB_REPOSITORY}"
fi

"${SCRIPT_DIR}/scripts/build-module-metadata-yq4.sh" "${TAG_NAME}" "${DIST_DIR}" "${REPO}"
cp README.md "${DIST_DIR}"

if [[ $(curl -L "https://raw.githubusercontent.com/${REPO}/${PUBLISH_BRANCH}/index.yaml") == "404: Not Found" ]]; then
  echo "No existing catalog found"
else
  curl -LO "https://raw.githubusercontent.com/${REPO}/${PUBLISH_BRANCH}/index.yaml"
fi

"${SCRIPT_DIR}/scripts/merge-module-metadata-yq4.sh" "${DIST_DIR}"
