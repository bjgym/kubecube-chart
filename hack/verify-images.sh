#!/usr/bin/env bash

#Copyright 2021 KubeCube Authors
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

# Fail when images.list disagrees with the image tags declared in values.yaml.
#
# Two files describe the same images and two different consumers read them: the
# chart deploys the tags from global.images, and the installer pre-pulls every
# line of images.list (kubecube-installer/install_k8s.sh). A tag bumped in one
# file and not the other leaves the pre-pull fetching an image the cluster never
# runs, which is the one failure an air-gapped install cannot absorb: the pull
# succeeds and the pod still cannot start.
#
# The check is one-directional by design. images.list also carries images that
# no values.yaml key describes - subchart and hotplug images, and older ingress
# controller tags kept for clusters on older releases - so requiring every line
# to be derivable would fail on the current, correct file. What is checked is
# the direction that breaks a deployment: nothing values.yaml declares may be
# absent from the list.
#
# Usage: hack/verify-images.sh [chart-dir]

set -euo pipefail

chart_dir="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
values="${chart_dir}/values.yaml"
list="${chart_dir}/images.list"

if [ ! -f "${values}" ]; then
  echo "verify-images: missing ${values}" >&2
  exit 2
fi
if [ ! -f "${list}" ]; then
  echo "verify-images: missing ${list}" >&2
  exit 2
fi

# read_scalar FILE BLOCK KEY - the value of "    KEY: value" inside "  BLOCK:"
read_scalar() {
  local file="$1" block="$2" key="$3" in_block=0 line
  while IFS= read -r line; do
    line="${line%$'\r'}"
    case "${line}" in
      "  ${block}:") in_block=1; continue ;;
    esac
    if [ "${in_block}" = 1 ]; then
      case "${line}" in
        "    ${key}:"*) printf '%s' "${line#*: }"; return 0 ;;
        "  "*) ;;
        *) return 1 ;;
      esac
    fi
  done < "${file}"
  return 1
}

# image_entries FILE - every "key: value" line of the "  images:" block
image_entries() {
  local file="$1" in_block=0 line
  while IFS= read -r line; do
    line="${line%$'\r'}"
    case "${line}" in
      "  images:") in_block=1; continue ;;
    esac
    if [ "${in_block}" = 1 ]; then
      case "${line}" in
        "    "*) printf '%s\n' "${line#"    "}" ;;
        "  "*) ;;
        *) return 0 ;;
      esac
    fi
  done < "${file}"
}

registry="$(read_scalar "${values}" hub registry)"
project="$(read_scalar "${values}" hub project)"
if [ -z "${registry}" ] || [ -z "${project}" ]; then
  echo "verify-images: global.hub.registry and global.hub.project must both be set in ${values}" >&2
  exit 2
fi

listed=()
while IFS= read -r line; do
  line="${line%$'\r'}"
  case "${line}" in
    ""|\#*) ;;
    *) listed+=("${line}") ;;
  esac
done < "${list}"

status=0
checked=0
while IFS= read -r entry; do
  case "${entry}" in
    ""|\#*) continue ;;
  esac
  key="${entry%%:*}"
  value="${entry#*: }"
  ref="${registry}/${project}/${value}"
  checked=$((checked + 1))

  found=0
  for candidate in "${listed[@]}"; do
    if [ "${candidate}" = "${ref}" ]; then
      found=1
      break
    fi
  done

  if [ "${found}" = 0 ]; then
    echo "MISSING  global.images.${key} declares ${ref}, which images.list does not contain" >&2
    status=1
  fi
done < <(image_entries "${values}")

if [ "${status}" != 0 ]; then
  echo "verify-images: images.list is out of date; the installer would pre-pull an image the chart does not deploy" >&2
  exit 1
fi

echo "verify-images: ${checked} image(s) declared in global.images are present in images.list"
