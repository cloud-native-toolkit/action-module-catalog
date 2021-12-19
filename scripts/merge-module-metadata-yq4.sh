#!/usr/bin/env bash

UPDATE_DIR="$1"
INDEX_DIR="$2"
if [[ -z "${INDEX_DIR}" ]]; then
  INDEX_DIR="."
fi

if [[ -f "${INDEX_DIR}/index.yaml" ]]; then
  echo "Merging versions"
  yq4 e '.versions' "${INDEX_DIR}/index.yaml" | yq4 e '{"versions": .}' - > tmp.yaml
  yq4 eval-all 'select(fileIndex == 0) *+ select(fileIndex == 1)' "${UPDATE_DIR}/module.yaml" tmp.yaml > "${UPDATE_DIR}/module.tmp.yaml"
  cp "${UPDATE_DIR}/module.tmp.yaml" "${UPDATE_DIR}/module.yaml"
  rm "${UPDATE_DIR}/module.tmp.yaml"
  rm tmp.yaml
fi

cp "${UPDATE_DIR}/module.yaml" "${UPDATE_DIR}/index.yaml"
rm "${UPDATE_DIR}/module.yaml"
