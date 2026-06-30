#!/usr/bin/env bash
#
# Build one image (base + all its add-ons) without pushing.
#
# Layers are written to the GitHub Actions cache (type=gha) so the
# publish-ghcr and publish-nexus jobs can restore them via --cache-from
# instead of rebuilding from scratch.
#
# Required environment variables:
#   BASE_TAG    Moving base tag, e.g. ubuntu-24.04
#   CONTEXT     Docker build context path
#   DOCKERFILE  Path to the Dockerfile
#   TARGET      Build stage for the base image (empty = final stage)
#   BUILD_ARGS  Space-separated KEY=VALUE build arguments
#   ADDONS      Space-separated add-on stage names
set -euo pipefail

: "${BASE_TAG:?BASE_TAG is required}"
: "${CONTEXT:?CONTEXT is required}"
: "${DOCKERFILE:?DOCKERFILE is required}"

# Common build-args (e.g. DISTRO=ubuntu VERSION=24.04) apply to every stage.
common_args=()
for kv in ${BUILD_ARGS:-}; do
  common_args+=(--build-arg "${kv}")
done

# 1. Base image: the image's `target` stage (or the final stage).
base_target_arg=()
[ -n "${TARGET:-}" ] && base_target_arg=(--target "${TARGET}")
echo "::group::Building base ${BASE_TAG}"
docker buildx build \
  --file "${DOCKERFILE}" \
  "${common_args[@]}" "${base_target_arg[@]}" \
  --cache-to "type=gha,mode=max,scope=${BASE_TAG}" \
  --tag "local/build-deps:${BASE_TAG}" \
  --load \
  "${CONTEXT}"
echo "::endgroup::"

# 2. Add-ons: each is a --target stage in the same Dockerfile.
for addon in ${ADDONS:-}; do
  echo "::group::Building add-on ${addon}"
  docker buildx build \
    --file "${DOCKERFILE}" \
    "${common_args[@]}" --target "${addon}" \
    --cache-to "type=gha,mode=max,scope=${BASE_TAG}-${addon}" \
    --tag "local/build-deps:${BASE_TAG}-${addon}" \
    --load \
    "${CONTEXT}"
  echo "::endgroup::"
done
