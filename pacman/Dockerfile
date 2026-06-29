# PLACEHOLDER — OpenModelica build-deps image for Arch Linux.
#
# Not implemented yet. Use the same layout as ../ubuntu/Dockerfile: a single
# multi-stage Dockerfile, with these stages:
#   base     OpenModelica build dependencies only
#   venv     Python virtualenv at /opt/venv, built in isolation and copied later
#   full     the published base image (build-deps:arch-rolling)
#   <addon>  optional add-on stages (FROM full)
#
# Arch is rolling-release, so there is no version build-arg:
#   FROM archlinux:latest AS base
#
# Note: pacman-based, with no OpenModelica apt repo — install the build
# dependencies directly with pacman, and pin reproducible snapshots via a
# date-stamped immutable tag (arch-rolling-YYYY.MM.DD).
#
# To implement:
#   1. Replace this file with a real multi-stage Dockerfile (see
#      ../ubuntu/Dockerfile and RELEASING.md).
#   2. Add the arch entry to .ci/matrix.yml
#      (context: arch, dockerfile: arch/Dockerfile, target: full).
#   3. Open a PR; build.yml will build it.
#
# Until then Arch is intentionally absent from .ci/matrix.yml, so CI does not try
# to build it.
