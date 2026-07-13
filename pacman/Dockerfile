# Multi-stage, shared image for Arch Linux.
#
# Arch is rolling-release with no version build-arg; uses archlinux:latest and
# pins to date-stamped immutable tags (arch-rolling-YYYY.MM.DD) via CI/build.yml.
# Arch has no OpenModelica pacman repository, so the build dependencies are
# installed directly with pacman (there is no `apt build-dep` equivalent).
# Package names were resolved against Arch's main repository.
#
# Stages / build targets:
#   base        OpenModelica build dependencies (toolchain + core libraries)
#   venv        Python virtualenv at /opt/venv, built in isolation and copied later
#   full        the published BASE image: base + Qt6 + OpenSceneGraph + python venv
#
# Build the base image (the `full` target):
#   docker build --target full --tag build-deps:arch-rolling pacman
#
# CI passes the --target per image from .ci/matrix.yml.

# ── base: OpenModelica build dependencies only ────────────────────────────────
FROM archlinux:latest AS base

# Image / OCI metadata (inherited by the stages built FROM this one)
LABEL maintainer="AnHeuermann" \
      description="OpenModelica build-deps Docker Image" \
      organization="OpenModelica"

LABEL org.opencontainers.image.vendor="OpenModelica" \
      org.opencontainers.image.authors="AnHeuermann" \
      org.opencontainers.image.description="OpenModelica build-deps base image" \
      org.opencontainers.image.source="https://github.com/OpenModelica/build-deps" \
      org.opencontainers.image.license="MIT"

ENV SHELL=/bin/bash \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Core toolchain and libraries needed to build the OpenModelica compiler.
# Mirrors OMCompiler/README.Linux.md §1.2 (autotools/cmake, g++/gfortran, clang,
# LAPACK/BLAS, hdf5, hwloc, boost, libcurl, expat, ncurses/readline, …).
RUN pacman -Syu --noconfirm \
  && pacman -S --noconfirm \
    autoconf \
    automake \
    bash \
    bison \
    boost \
    bzip2 \
    ccache \
    clang \
    cmake \
    coreutils \
    curl \
    expat \
    flex \
    gcc \
    gcc-fortran \
    git \
    gnuplot \
    hdf5 \
    hwloc \
    jq \
    java-runtime-openjdk \
    lapack \
    libtool \
    libxml2 \
    libxslt \
    linux-headers \
    make \
    ncurses \
    openblas \
    openmp \
    openssl \
    patch \
    pkgconf \
    readline \
    tar \
    unzip \
    util-linux \
    wget \
    xz \
    zip \
    zlib

# CI mounts fresh named volumes under /cache; Docker seeds an empty volume with
# the mount point's image permissions, so create them world-writable for the
# non-root Jenkins uid (sccache/runtest/omlibrary caches).
RUN mkdir -p /cache/sccache /cache/runtest /cache/omlibrary \
  && chmod -R 0777 /cache

# ── venv: Python tooling, isolated so it caches independently ─────────────────
# Built once and copied into `full`. Uses the same python3 as `full` (same
# base image), so the relocated /opt/venv works there unchanged.
FROM base AS venv
RUN pacman -S --noconfirm python python-pip
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
# Use permalink for doc/UsersGuide/source/requirements.txt to keep builds
# deterministic.
RUN pip install --no-cache-dir \
    fmpy==0.3.29 \
    junit_xml \
    lxml \
    ompython==3.6.0 \
    PyGithub \
    simplejson \
    svgwrite \
  && pip install --no-cache-dir -r \
    https://raw.githubusercontent.com/OpenModelica/OpenModelica/9c0dc9a8ab50ba652109584cb3fecaef86640b66/doc/UsersGuide/source/requirements.txt

# ── full: the published base image ────────────────────────────────────────────
#   - Qt6 for OMEdit (base + the modules OpenModelica links against)
#   - OpenSceneGraph for the OMEdit 3D animation view
#   - doc generators (doxygen, graphviz) and a few build utilities
FROM base AS full

# Package lists as build-args, so they are easy to read and to override.
#   - QT_PKGS   : Qt6 modules OMEdit builds against
#   - EXTRA_PKGS: OpenSceneGraph, doc generators and misc build utilities
ARG QT_PKGS="\
    qt6-base \
    qt6-declarative \
    qt6-httpserver \
    qt6-quick3d \
    qt6-scxml \
    qt6-serialport \
    qt6-shadertools \
    qt6-svg \
    qt6-tools \
    qt6-websockets"
ARG EXTRA_PKGS="\
    doxygen \
    openscenegraph"
RUN pacman -S --noconfirm ${QT_PKGS} ${EXTRA_PKGS}

# Pull in the venv built in its own stage instead of rebuilding it here.
COPY --from=venv /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
