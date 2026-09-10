#!/usr/bin/env bash
#
# Build one image (base + all its add-ons) and push it to every registry in
# REGISTRIES, skipping the stages that are already published under the same
# recipe hash.
#
# Both registries are fed from a single `docker buildx build`, so an image is
# built once per run and both registries end up with the same digest.
#
# The base image is always pushed under the moving tag (<os>-<version>).
# When TAG includes a semver suffix (<os>-<version>-<semver>), an additional
# immutable tag is pushed alongside it — or, when the moving tag already holds
# exactly this recipe, added to the digest that is already published. Each
# add-on is a build STAGE (--target) in the same Dockerfile and follows the
# same moving/immutable pattern. An add-on is built on top of the image its
# parent stage was published as, pinned by digest, so the parent's stages are
# never re-run and the add-on provably extends the image it says it does.
#
# Required environment variables:
#   REGISTRIES     Space-separated image repositories, e.g.
#                  "ghcr.io/openmodelica/build-deps docker.openmodelica.org/build-deps"
#   TAG            Base tag (e.g. ubuntu-24.04) or release tag (ubuntu-24.04-2.1.0)
#   SIGN           "true" to cosign-sign the pushed immutable tags (keyless
#                  OIDC), else "false". Only immutable tags in SIGN_REGISTRY
#                  are signed: the moving tag points at the same digest, so one
#                  signature per image covers both, and moving-only publishes
#                  (no semver) sign nothing.
#   SIGN_REGISTRY  The one repository whose immutable tags are signed (GHCR).
#   FORCE          "true" to rebuild and push regardless of the recipe hash
set -euo pipefail

: "${REGISTRIES:?REGISTRIES is required}"
: "${TAG:?TAG is required}"
SIGN="${SIGN:-false}"
SIGN_REGISTRY="${SIGN_REGISTRY:-}"
FORCE="${FORCE:-false}"

# shellcheck source=.ci/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Resolve the tag to base_tag / semver / context / dockerfile / target /
# build_args / addons.  semver is empty for moving-only publishes.
resolve_image "${TAG}"

IMAGE_TAGS=()
IMMUTABLE_TAGS=()

publish_stage() {
  # $1 = stage, $2 = moving tag, $3 = immutable tag (empty → skip),
  # remaining args go to `docker buildx`.
  local stage="$1" moving="$2" immutable="$3"
  shift 3
  local registry tag_args=() want
  want="$(context_hash "${stage}")"
  for registry in ${REGISTRIES}; do
    tag_args+=(--tag "${registry}:${moving}")
    IMAGE_TAGS+=("${registry}:${moving}")
    if [[ -n "${immutable}" ]]; then
      tag_args+=(--tag "${registry}:${immutable}")
      IMAGE_TAGS+=("${registry}:${immutable}")
      if [[ "${registry}" == "${SIGN_REGISTRY}" ]]; then
        IMMUTABLE_TAGS+=("${registry}:${immutable}")
      fi
    fi
  done
  if [[ "${FORCE}" != "true" ]] && tag_current "${want}" "${moving}"; then
    # The published image is the one this recipe builds, so a release only
    # needs its immutable tag: point that tag at the digest that is already
    # there instead of building a second, equivalent image. --prefer-index
    # keeps buildx from wrapping the manifest in an index, which would give
    # the immutable tag a digest of its own.
    if [[ -z "${immutable}" ]]; then
      echo "Up to date: ${moving} — not rebuilding it"
      return
    fi
    for registry in ${REGISTRIES}; do
      echo "Tagging ${registry}:${moving} as ${immutable} — same digest, no rebuild"
      docker buildx imagetools create --prefer-index=false \
        --tag "${registry}:${immutable}" "${registry}:${moving}"
    done
    return
  fi
  echo "::group::Building ${moving}"
  # --provenance=false: without it buildx wraps every image in an OCI index
  # with an extra attestation manifest, which piles up as untagged versions
  # on GHCR on every push.
  docker buildx build \
    --pull \
    --provenance=false \
    --file "${dockerfile}" \
    "${tag_args[@]}" \
    --label "${HASH_LABEL}=${want}" \
    --cache-from "type=gha,scope=${moving}" \
    --push \
    "$@" \
    "${context}"
  echo "::endgroup::"
}

# Common build-args (e.g. UBUNTU_VERSION) apply to every stage.
common_args=()
for kv in ${build_args}; do
  common_args+=(--build-arg "${kv}")
done

# The base image is the image's `target` stage (or the final stage); each
# add-on is a further stage of the same Dockerfile.
# Each add-on is built on the image its parent stage was just published as, so
# it inherits that exact digest rather than re-running the parent's
# instructions; see parent_context_args.
while IFS='|' read -r stage moving immutable; do
  target_arg=()
  [ -n "${stage}" ] && target_arg=(--target "${stage}")
  # Command substitution, not a process substitution: parent_context_args exits
  # non-zero when it cannot resolve the parent, and that has to end the run.
  parent_args=()
  parent_out=$(parent_context_args "${stage}") || exit 1
  [ -n "${parent_out}" ] && mapfile -t parent_args <<<"${parent_out}"
  publish_stage "${stage}" "${moving}" "${immutable}" \
    "${common_args[@]}" "${target_arg[@]}" "${parent_args[@]}"
done < <(image_stage_tags)

# Sign the immutable tags (GHCR / cosign keyless). Signing is per digest, so
# the moving tag of the same image verifies too. Tags that were already
# published under this hash are signed as well, so a re-run of a release
# leaves every immutable tag signed even when nothing had to be rebuilt.
if [ "${SIGN}" = "true" ] && [ "${#IMMUTABLE_TAGS[@]}" -gt 0 ]; then
  for image in "${IMMUTABLE_TAGS[@]}"; do
    echo "Signing ${image}"
    COSIGN_EXPERIMENTAL=1 cosign sign --yes --registry-referrers-mode=oci-1-1 "${image}"
  done
fi

echo "Tags now current in the registries:"
printf '  %s\n' "${IMAGE_TAGS[@]}"
