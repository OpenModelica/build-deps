#!/usr/bin/env bash
#
# Decide whether one image needs building at all, so the expensive steps of a
# job (freeing disk space, setting up buildx, building) can be skipped for
# images whose recipe did not change.
#
# Prints `build=true` or `build=false`, and appends the same line to
# $GITHUB_OUTPUT when running under GitHub Actions. Reading the registries is
# all it does; it never builds anything.
#
# Required environment variables:
#   TAG         Base tag (e.g. ubuntu-24.04) or release tag (ubuntu-24.04-2.1.0)
#   REGISTRIES  Space-separated image repositories to check
#   FORCE       "true" to answer build=true without asking the registries
set -euo pipefail

: "${TAG:?TAG is required}"
: "${REGISTRIES:?REGISTRIES is required}"
FORCE="${FORCE:-false}"

# shellcheck source=.ci/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

resolve_image "${TAG}"

answer() {
  echo "build=$1"
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "build=$1" >> "${GITHUB_OUTPUT}"
  fi
  exit 0
}

if [ "${FORCE}" = "true" ]; then
  echo "FORCE is set — rebuilding ${TAG} without checking the registries"
  answer true
fi

while IFS='|' read -r stage moving immutable; do
  if stage_needs_build "${stage}" "${moving}" "${immutable}"; then
    answer true
  fi
done < <(image_stage_tags)

answer false
