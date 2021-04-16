#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0") && pwd -P)
MODULE_DIR=$PWD

VERSION="$1"
DEST_DIR="$2"
REPO_SLUG="$3"

if [[ -z "${VERSION}" ]]; then
  VERSION="0.0.0"
fi

if [[ -z "${DEST_DIR}" ]]; then
  DEST_DIR="${MODULE_DIR}/dist"
fi

if [[ -z "${REPO_SLUG}" ]]; then
  REPO_SLUG=$(git remote get-url origin | sed -E "s/.*github.com:(.*).git/\1/g")
fi

mkdir -p "${DEST_DIR}"

cp "${MODULE_DIR}/module.yaml" "${DEST_DIR}/module.yaml"

echo "id: github.com/${REPO_SLUG}" > "${DEST_DIR}/module.yaml"
cat "${MODULE_DIR}/module.yaml" >> "${DEST_DIR}/module.yaml"

PREFIX='versions[0].'

yq w -i "${DEST_DIR}/module.yaml" "${PREFIX}version" "${VERSION}"

set -e

cat "${MODULE_DIR}/variables.tf" | \
  grep -vE "^ *#" | \
  tr '\n' '~' | \
  sed $'s/variable/\\\nvariable/g' | \
  grep variable | \
  while read variable; do
    name=$(echo "$variable" | sed -E "s/variable +\"([^ ]+)\".*/\1/g")
    type=$(echo "$variable" | grep -E "type +=" | perl -pe "s/.*type += +(.+?)( *description *=.*| *type *=.*| *default *=.*|[ ~]*}[ ~]*$)/\1/g" | tr '~' '\n')
    description=$(echo "$variable" | grep -E "description +=" | perl -pe "s/.*description += +(.+?)( *description *=.*| *type *=.*| *default *=.*|[ ~]*}[ ~]*$)/\1/g" | tr '~' '\n' | sed -E "s/^\"(.*)\"$/\1/g")
    defaultValue=$(echo "$variable" | grep -E "default +=" | perl -pe "s/.*default += +(.+?)( *description *=.*| *type *=.*| *default *=.*|[ ~]*}[ ~]*$)/\1/g" | tr '~' '\n')

    if [[ -z "${type}" ]]; then
      type="string"
    fi

    if [[ -z $(yq r "${DEST_DIR}/module.yaml" "${PREFIX}variables(name==${name}).name") ]]; then
      yq w -i "${DEST_DIR}/module.yaml" "${PREFIX}variables[+].name" "${name}"
    fi

    yq w -i "${DEST_DIR}/module.yaml" "${PREFIX}variables(name==${name}).type" "${type}"
    if [[ -n "${description}" ]]; then
      yq w -i "${DEST_DIR}/module.yaml" "${PREFIX}variables(name==${name}).description" "${description}"
    fi
    if [[ -n "${defaultValue}" ]]; then
      defaultValue=$(echo "${defaultValue}" | xargs)

      if [[ "${type}" == "string" ]]; then
        defaultValue=${defaultValue//\"/}
        tag=(--tag '!!str')
      else
        tag=()
      fi

      yq w -i "${DEST_DIR}/module.yaml" "${PREFIX}variables(name==${name}).default" "${tag[@]}" "${defaultValue}"
      yq w -i "${DEST_DIR}/module.yaml" "${PREFIX}variables(name==${name}).optional" "true"
    fi
done

cat "${MODULE_DIR}/outputs.tf" | \
  grep -vE "^ *#" | \
  tr '\n' ' ' | \
  sed $'s/output/\\\noutput/g' | \
  grep output | \
  while read output; do
    name=$(echo "$output" | sed -E "s/output +\"([^ ]+)\".*/\1/g")
    description=$(echo "$output" | sed -E "s/.*description += *\"([^\"]*)\".*/\1/g")

    if [[ -z $(yq r "${DEST_DIR}/module.yaml" "${PREFIX}outputs(name==${name}).name") ]]; then
      yq w -i "${DEST_DIR}/module.yaml" "${PREFIX}outputs[+].name" "${name}"
    fi

    if [[ -n "${description}" ]]; then
      yq w -i "${DEST_DIR}/module.yaml" "${PREFIX}outputs(name==${name}).description" "${description}"
    fi
done
