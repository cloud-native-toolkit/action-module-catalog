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

yq4 e '... comments=""' "${MODULE_DIR}/module.yaml" > "${DEST_DIR}/module.yaml"

echo "id: github.com/${REPO_SLUG}" > "${DEST_DIR}/module.yaml"
cat "${MODULE_DIR}/module.yaml" >> "${DEST_DIR}/module.yaml"

if [[ "${VERSION}" =~ v{0,1}0.0.0 ]]; then
  echo "Found version 0.0.0. Creating empty metadata."
  yq4 e -i '.versions = []' "${DEST_DIR}/module.yaml"
  exit 0
fi

export VERSION

yq4 e -i '.versions[0].version=env(VERSION)' "${DEST_DIR}/module.yaml"

set -e

cat "${MODULE_DIR}/variables.tf" | \
  grep -vE "^ *#" | \
  tr '\n' '~' | \
  sed $'s/variable/\\\nvariable/g' | \
  grep variable | \
  while read variable; do
    name=$(echo "$variable" | sed -E "s/variable +\"([^ ]+)\".*/\1/g")
    type=$(echo "$variable" | grep -E "type +=" | perl -pe "s/.*type += +(.+?)( *description *=.*| *sensitive *=.*| *type *=.*| *validation *{.*| *default *=.*|[ ~]*}[ ~]*$)/\1/g" | tr '~' '\n')
    description=$(echo "$variable" | grep -E "description +=" | perl -pe "s/.*description += +(.+?)( *description *=.*| *sensitive *=.*| *type *=.*| *validation *{.*| *default *=.*|[ ~]*}[ ~]*$)/\1/g" | tr '~' '\n' | sed -E "s/^\"(.*)\"$/\1/g")
    defaultValue=$(echo "$variable" | grep -E "default +=" | perl -pe "s/.*default += +(.+?)( *description *=.*| *sensitive *=.*| *type *=.*| *validation *{.*| *default *=.*|[ ~]*}[ ~]*$)/\1/g" | tr '~' '\n')
    sensitive=$(echo "$variable" | grep -E "sensitive +=" | perl -pe "s/.*sensitive += +(.+?)( *description *=.*| *sensitive *=.*| *type *=.*| *validation *{.*| *default *=.*|[ ~]*}[ ~]*$)/\1/g" | tr '~' '\n')

    if [[ -z "${type}" ]]; then
      type="string"
    fi

    if [[ -z $(NAME="${name}" yq4 e '.versions[0] | .variables[] | select(.name == env(NAME)) | .name' "${DEST_DIR}/module.yaml") ]]; then
      NAME="${name}" yq4 e -i '.versions[0].variables += {"name": env(NAME)}' "${DEST_DIR}/module.yaml"
    fi

    NAME="${name}" TYPE="${type}" DESC="${description}" yq4 e -i 'with(.versions[0] | .variables[] | select(.name == env(NAME)); .type = env(TYPE) | .description = env(DESC))' "${DEST_DIR}/module.yaml"

    if [[ -n "${sensitive}" ]]; then
      NAME="${name}" SENSITIVE="${sensitive}" yq4 e -i 'with(.versions[0] | .variables[] | select(.name == env(NAME)); .sensitive = env(SENSITIVE) == "true")' "${DEST_DIR}/module.yaml"
    fi

    if [[ -n "${defaultValue}" ]]; then
      defaultValue=$(echo "${defaultValue}" | xargs)

      if [[ "${type}" == "string" ]]; then
        defaultValue=${defaultValue//\"/}

        if [[ -z "${defaultValue}" ]]; then
          NAME="${name}" yq4 e -i 'with(.versions[0] | .variables[] | select(.name == env(NAME)); .default = "")' "${DEST_DIR}/module.yaml"
        else
          NAME="${name}" DEFAULT="${defaultValue}" yq4 e -i 'with(.versions[0] | .variables[] | select(.name == env(NAME)); .default = env(DEFAULT)) tag= "!!str"' "${DEST_DIR}/module.yaml"
        fi
      else
        NAME="${name}" DEFAULT="${defaultValue}" yq4 e -i 'with(.versions[0] | .variables[] | select(.name == env(NAME)); .default = env(DEFAULT))' "${DEST_DIR}/module.yaml"
      fi
    fi
done

if [[ -f "${MODULE_DIR}/outputs.tf" ]]; then
  cat "${MODULE_DIR}/outputs.tf" | \
    grep -vE "^ *#" | \
    tr '\n' ' ' | \
    sed $'s/output/\\\noutput/g' | \
    grep output | \
    while read output; do
      name=$(echo "$output" | sed -E "s/output +\"([^ ]+)\".*/\1/g")
      description=$(echo "$output" | sed -E "s/.*description += *\"([^\"]*)\".*/\1/g")

      if [[ -z $(yq4 e '.versions[0] | .outputs // ""' "${DEST_DIR}/module.yaml") ]]; then
        yq4 e -i '.versions[0].outputs = []' "${DEST_DIR}/module.yaml"
      fi

      if [[ -z $(NAME="${name}" yq4 e '.versions[0] | .outputs[] | select(.name == env(NAME)) | .name' "${DEST_DIR}/module.yaml") ]]; then
        NAME="${name}" yq4 e -i -P '.versions[0].outputs += {"name": env(NAME)}' "${DEST_DIR}/module.yaml"
      fi

      if [[ -n "${description}" ]]; then
        NAME="${name}" DESC="${description}" yq4 e -i 'with(.versions[0] | .outputs[] | select(.name == env(NAME)); .description = env(DESC))' "${DEST_DIR}/module.yaml"
      fi
  done
else
  yq4 e -i '.versions[0].outputs=[]' "${DEST_DIR}/module.yaml"
fi
