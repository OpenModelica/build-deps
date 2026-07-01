#!/usr/bin/env bash
#
# Build and push one image (base + all its add-ons) to a registry.
#
# The base image is always pushed under the moving tag (<os>-<version>).
# When TAG includes a semver suffix (<os>-<version>-<semver>), an additional
# immutable tag is pushed alongside it. Each add-on is a build STAGE (--target)
# in the same Dockerfile and follows the same moving/immutable pattern; shared
# layers come from the build cache, so the base is effectively built only once.
#
# Required environment variables:
#   REGISTRY  Image repository, e.g. ghcr.io/openmodelica/build-deps
#   TAG       Base tag (e.g. ubuntu-24.04) or release tag (e.g. ubuntu-24.04-2.1.0)
#   SIGN      "true" to cosign-sign every pushed tag (keyless OIDC), else "false"
set -euo pipefail

: "${REGISTRY:?REGISTRY is required}"
: "${TAG:?TAG is required}"
SIGN="${SIGN:-false}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve the tag to base_tag / semver / context / dockerfile / target /
# build_args / addons.  semver is empty for moving-only publishes.
eval "$(python3 "${SCRIPT_DIR}/matrix.py" image "${TAG}")"

PUSHED_TAGS=()

build_and_push() {
  # $1 = moving tag, $2 = immutable tag (empty → skip), remaining args go to `docker buildx`.
  local moving="$1" immutable="$2"
  shift 2
  local tag_args=(--tag "${REGISTRY}:${moving}")
  if [[ -n "${immutable}" ]]; then
    tag_args+=(--tag "${REGISTRY}:${immutable}")
  fi
  echo "::group::Building ${moving}"
  docker buildx build \
    --pull \
    --file "${dockerfile}" \
    "${tag_args[@]}" \
    --cache-from "type=gha,scope=${moving}" \
    --push \
    "$@" \
    "${context}"
  echo "::endgroup::"
  PUSHED_TAGS+=("${REGISTRY}:${moving}")
  if [[ -n "${immutable}" ]]; then
    PUSHED_TAGS+=("${REGISTRY}:${immutable}")
  fi
}

# Common build-args (e.g. UBUNTU_VERSION) apply to every stage.
common_args=()
for kv in ${build_args}; do
  common_args+=(--build-arg "${kv}")
done

# 1. Base image: the image's `target` stage (or the final stage).
base_target_arg=()
if [[ -n "${target}" ]]; then
  base_target_arg=(--target "${target}")
fi
build_and_push "${base_tag}" "${semver:+${base_tag}-${semver}}" \
  "${common_args[@]}" "${base_target_arg[@]}"

# 2. Add-ons: each is a --target stage in the same Dockerfile.
for addon in ${addons}; do
  build_and_push "${base_tag}-${addon}" "${semver:+${base_tag}-${addon}-${semver}}" \
    "${common_args[@]}" --target "${addon}"
done

# 3. Optionally sign every pushed tag (GHCR / cosign keyless).
if [ "${SIGN}" = "true" ]; then
  for image in "${PUSHED_TAGS[@]}"; do
    echo "Signing ${image}"
    COSIGN_EXPERIMENTAL=1 cosign sign --yes --registry-referrers-mode=oci-1-1 "${image}"
  done
fi

printf '%s\n' "${PUSHED_TAGS[@]}"
