# PLACEHOLDER — OpenModelica build-deps image for RPM-based distros.
#
# Not implemented yet. Will follow the same layout as ../apt/Dockerfile: a
# single multi-stage Dockerfile covering all supported versions of Fedora,
# AlmaLinux, Rocky Linux, and RHEL, with these stages:
#   base     OpenModelica build dependencies only (dnf builddep openmodelica)
#   full     the published base image (build-deps:<os>-<ver>)
#   <addon>  optional add-on stages (FROM full)
#
# The distro and version are selected with build-args, e.g.:
#   ARG DISTRO=fedora
#   ARG VERSION=42
#   FROM ${DISTRO}:${VERSION} AS base
#
# Enterprise distros (AlmaLinux, Rocky Linux, RHEL) require EPEL and the CRB
# repo to be enabled before dnf can resolve all build dependencies:
#   dnf install -y epel-release
#   dnf config-manager --set-enabled crb
# This can be handled with a case "${ID}" block, similar to how apt/Dockerfile
# selects Qt package sets per distro version.
#
# To implement:
#   1. Replace this file with a real multi-stage Dockerfile (see
#      ../apt/Dockerfile and RELEASING.md).
#   2. Add entries to .ci/matrix.yml
#      (context: rpm, dockerfile: rpm/Dockerfile, target: full,
#       build_args: { DISTRO: fedora, VERSION: "42" }).
#   3. Open a PR; build.yml will build it.
#
# Until then RPM-based images are intentionally absent from .ci/matrix.yml,
# so CI does not try to build them.
