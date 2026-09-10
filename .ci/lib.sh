#!/usr/bin/env bash
#
# Shared helpers for build.sh, publish.sh and registry-status.sh.
#
# An image carries the hash of the recipe it was built from as the
# `org.openmodelica.build-deps.hash` label (the same label apt-build's
# Jenkinsfile uses for its own build-deps images). Comparing that label with
# the hash of the current checkout tells us whether an image has to be
# rebuilt, so a push that touches only some of the Dockerfiles does not
# rebuild everything.
#
# Sourcing this file gives access to the variables of one image, resolved
# from a tag by `resolve_image`: context, dockerfile, target, build_args,
# addons, base_tag and semver.

# shellcheck disable=SC2154 # the image variables are assigned by resolve_image

HASH_LABEL="org.openmodelica.build-deps.hash"

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve a moving or immutable tag to the image it belongs to.
resolve_image() {
  eval "$(python3 "${LIB_DIR}/matrix.py" image "$1")"
}

# Hash of everything that goes into one image: the build-args, the stage that is
# built, the instructions building that stage would actually run, and the rest of
# the build context. `matrix.py recipe` reduces the Dockerfile to the target's
# stage closure, so editing one stage invalidates that stage and its descendants
# rather than every image the Dockerfile serves.
context_hash() {
  local stage="$1"
  {
    echo "stage=${stage}"
    for kv in ${build_args}; do echo "build_arg=${kv}"; done | LC_ALL=C sort
    python3 "${LIB_DIR}/matrix.py" recipe "${dockerfile}" "${stage}"
    find "${context}" -type f ! -path "${dockerfile}" -print |
      LC_ALL=C sort -u | xargs -r sha256sum
  } | sha256sum | cut -c1-16
}

# Every image this tag publishes, as `stage|moving tag|immutable tag` lines:
# the base image first, then one per add-on. The immutable field is empty
# unless the tag carried a semver.
image_stage_tags() {
  printf '%s|%s|%s\n' "${target}" "${base_tag}" "${semver:+${base_tag}-${semver}}"
  local addon
  for addon in ${addons}; do
    printf '%s|%s|%s\n' "${addon}" "${base_tag}-${addon}" \
      "${semver:+${base_tag}-${addon}-${semver}}"
  done
}

# Hash label of an image in a registry, empty when the registry says the tag
# does not exist. Returns 2 when we could not ask at all.
registry_hash() {
  local image="$1" out attempt
  for attempt in 1 2 3; do
    if out=$(docker buildx imagetools inspect "${image}" \
               --format "{{ index .Image.Config.Labels \"${HASH_LABEL}\" }}" 2>&1); then
      printf '%s\n' "${out}" | tail -n1
      return 0
    fi
    case "${out}" in
      *"not found"*|*"manifest unknown"*|*MANIFEST_UNKNOWN*|*NAME_UNKNOWN*|\
      *"repository name not known"*|*"does not exist"*)
        echo "${image}: not in the registry yet" >&2
        return 0
        ;;
    esac
    echo "${image}: cannot inspect (attempt ${attempt}/3): ${out}" >&2
    if [ "${attempt}" -lt 3 ]; then
      sleep $((attempt * 15))
    fi
  done
  echo "::error::${image}: cannot read the ${HASH_LABEL} label" >&2
  return 2
}

# True when every registry already carries `want` as the hash label of `tag`.
#
# A registry we could not reach ends the job: an image we cannot see is not an
# image we may assume is up to date, and rebuilding it blindly would paper
# over a broken registry.
tag_current() {
  local want="$1" tag="$2" registry image have rc
  for registry in ${REGISTRIES}; do
    image="${registry}:${tag}"
    rc=0
    have=$(registry_hash "${image}") || rc=$?
    if [ "${rc}" -ne 0 ]; then
      exit 1
    fi
    if [ "${have}" != "${want}" ]; then
      echo "${image}: ${have:-no hash label} != ${want}"
      return 1
    fi
    echo "${image}: up to date (${want})"
  done
}

# Digest of a tag in a registry, empty when the tag is not there. Returns 2
# when we could not ask at all, like registry_hash.
registry_digest() {
  local image="$1" out attempt
  for attempt in 1 2 3; do
    if out=$(docker buildx imagetools inspect "${image}" \
               --format "{{ .Manifest.Digest }}" 2>&1); then
      printf '%s\n' "${out}" | tail -n1
      return 0
    fi
    case "${out}" in
      *"not found"*|*"manifest unknown"*|*MANIFEST_UNKNOWN*|*NAME_UNKNOWN*|\
      *"repository name not known"*|*"does not exist"*)
        return 0
        ;;
    esac
    echo "${image}: cannot inspect (attempt ${attempt}/3): ${out}" >&2
    if [ "${attempt}" -lt 3 ]; then
      sleep $((attempt * 15))
    fi
  done
  echo "::error::${image}: cannot read its digest" >&2
  return 2
}

# Moving tag one stage is published under, empty when the stage is not an image
# of its own (an intermediate stage such as `base`, `venv` or `rustdeps`).
stage_moving_tag() {
  local want="$1" stage moving immutable
  while IFS='|' read -r stage moving immutable; do
    if [ "${stage}" = "${want}" ]; then
      printf '%s\n' "${moving}"
      return 0
    fi
  done < <(image_stage_tags)
}

# `--build-context` arguments that build `stage` on top of the image its parent
# stage is published as, printed one per line. Empty when the parent is not
# published as an image of its own.
#
# `FROM full` names a stage, not the published base image, so without this an
# add-on re-runs the base stage's apt-get upgrade and build-dep: slow, and it
# can leave the add-on on a different package set than the base image it claims
# to extend. Overriding the stage pins it to the digest the parent published.
#
# The caller has to have published the parent already. image_stage_tags lists
# the base image first and then the add-ons in matrix.yml order, so an add-on
# whose parent is another add-on has to come after it there.
parent_context_args() {
  local stage="$1" parent parent_tag registry digest rc=0
  parent=$(python3 "${LIB_DIR}/matrix.py" parent "${dockerfile}" "${stage}")
  [ -n "${parent}" ] || return 0
  parent_tag=$(stage_moving_tag "${parent}")
  [ -n "${parent_tag}" ] || return 0
  registry=${REGISTRIES%% *}
  digest=$(registry_digest "${registry}:${parent_tag}") || rc=$?
  if [ "${rc}" -ne 0 ]; then
    exit 1
  fi
  if [ -z "${digest}" ]; then
    echo "::error::${registry}:${parent_tag} is not published, so ${stage} has" \
         "no parent image to build on. Its parent must be published first:" \
         "check the add-on order in matrix.yml." >&2
    exit 1
  fi
  printf '%s\n' "--build-context" "${parent}=docker-image://${registry}@${digest}"
}

# True when one stage has work to do: a tag it would be pushed under is
# missing or was built from a different recipe.
stage_needs_build() {
  local stage="$1" moving="$2" immutable="$3" want
  want=$(context_hash "${stage}")
  tag_current "${want}" "${moving}" || return 0
  if [ -n "${immutable}" ]; then
    tag_current "${want}" "${immutable}" || return 0
  fi
  return 1
}
