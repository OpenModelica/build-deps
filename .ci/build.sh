#!/usr/bin/env bash
#
# Build one image (base + all its add-ons) without pushing, skipping the
# stages the registry already has under the same recipe hash. Used by the
# pull-request job: a PR that touches one Dockerfile only builds the images
# that Dockerfile serves.
#
# Layers are written to the GitHub Actions cache (type=gha) so a later build
# of the same stage can restore them via --cache-from instead of rebuilding
# from scratch.
#
# Required environment variables:
#   TAG         Moving base tag of the image, e.g. ubuntu-24.04
#   REGISTRIES  Space-separated image repositories to compare hashes against
#   FORCE       "true" to build every stage without asking the registries
set -euo pipefail

: "${TAG:?TAG is required}"
: "${REGISTRIES:?REGISTRIES is required}"
FORCE="${FORCE:-false}"

# shellcheck source=.ci/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

resolve_image "${TAG}"

# Common build-args (e.g. DISTRO=ubuntu VERSION=24.04) apply to every stage.
common_args=()
for kv in ${build_args}; do
  common_args+=(--build-arg "${kv}")
done

# The base image is the image's `target` stage (or the final stage); each
# add-on is a further stage of the same Dockerfile.
# Stages built in this run, so an add-on whose parent was just built reuses it
# from the local cache rather than the registry.
built_here=" "
while IFS='|' read -r stage moving immutable; do
  if [ "${FORCE}" != "true" ] && ! stage_needs_build "${stage}" "${moving}" "${immutable}"; then
    echo "Up to date: ${moving} — not building it"
    continue
  fi
  target_arg=()
  [ -n "${stage}" ] && target_arg=(--target "${stage}")
  # A parent that was skipped as up to date is published and was not built
  # here, so build on that image instead of re-running its instructions.
  parent_args=()
  parent=$(python3 "${LIB_DIR}/matrix.py" parent "${dockerfile}" "${stage}")
  if [ -n "${parent}" ] && [[ "${built_here}" != *" ${parent} "* ]]; then
    parent_out=$(parent_context_args "${stage}") || exit 1
    [ -n "${parent_out}" ] && mapfile -t parent_args <<<"${parent_out}"
  fi
  echo "::group::Building ${moving}"
  docker buildx build \
    --file "${dockerfile}" \
    "${common_args[@]}" "${target_arg[@]}" "${parent_args[@]}" \
    --label "${HASH_LABEL}=$(context_hash "${stage}")" \
    --cache-to "type=gha,mode=max,scope=${moving}" \
    --tag "local/build-deps:${moving}" \
    --load \
    "${context}"
  echo "::endgroup::"
  built_here="${built_here}${stage} "
done < <(image_stage_tags)
