FROM ubuntu:noble

# Image / OCI metadata
LABEL maintainer="AnHeuermann"
LABEL description="OpenModelica build-deps Docker Image "
LABEL organization="OpenModelica"

LABEL org.opencontainers.image.vendor="OpenModelica"
LABEL org.opencontainers.image.authors="AnHeuermann"
LABEL org.opencontainers.image.version="v1.26.0"
LABEL org.opencontainers.image.description="OpenModelica build-deps Docker Image "
LABEL org.opencontainers.image.source="https://github.com/OpenModelica/build-deps"
LABEL org.opencontainers.image.license="MIT"

ENV SHELL=/bin/bash

# Ensure DEBIAN_FRONTEND is only set during build
ARG DEBIAN_FRONTEND=noninteractive

# Install OpenModelica build-deps
RUN apt-get update                                                                                                                          \
  && apt-get upgrade -qy                                                                                                                    \
  && apt-get dist-upgrade -qy                                                                                                               \
  && apt-get install -qy                                                                                                                    \
    ca-certificates                                                                                                                         \
    curl                                                                                                                                    \
    gnupg                                                                                                                                   \
    lsb-release                                                                                                                             \
  && curl -fsSL https://build.openmodelica.org/apt/openmodelica.asc | gpg --dearmor -o /usr/share/keyrings/openmodelica-keyring.gpg          \
  && echo                                                                                                                                   \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/openmodelica-keyring.gpg] https://build.openmodelica.org/apt      \
    $(cat /etc/os-release | grep "\(UBUNTU\\|DEBIAN\\|VERSION\)_CODENAME" | sort | cut -d= -f 2 | head -1)                                  \
    nightly" | tee /etc/apt/sources.list.d/openmodelica.list > /dev/null                                                                    \
  && echo                                                                                                                                   \
    "deb-src [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/openmodelica-keyring.gpg] https://build.openmodelica.org/apt  \
    $(cat /etc/os-release | grep "\(UBUNTU\\|DEBIAN\\|VERSION\)_CODENAME" | sort | cut -d= -f 2 | head -1)                                  \
    nightly" | tee -a /etc/apt/sources.list.d/openmodelica.list > /dev/null                                                                 \
  && apt-get update                                                                                                                         \
  && apt-get build-dep -qy openmodelica                                                                                                     \
  && apt-get clean                                                                                                                          \
  && rm -rf /var/lib/apt/lists/*

# Install additional dependencies
#   - tools to build the User's Guide
#   - Python system packages
#   - Qt5, Qt6 packages
RUN apt-get update                      \
  && apt-get install -qy                \
    aspell                              \
    bibtex2html                         \
    bison                               \
    ccache                              \
    clang-tools                         \
    devscripts                          \
    docker.io                           \
    doxygen                             \
    equivs                              \
    flex                                \
    git                                 \
    gnuplot-nox                         \
    inkscape                            \
    intel-opencl-icd                    \
    latexmk                             \
    libcurl4-gnutls-dev                 \
    libmldbm-perl                       \
    libqt6core5compat6-dev              \
    libqt6opengl6-dev                   \
    libqt6openglwidgets6                \
    libqt6svg6-dev                      \
    locales                             \
    ocl-icd-opencl-dev                  \
    opencl-headers                      \
    pandoc                              \
    pipx                                \
    pocl-opencl-icd                     \
    poppler-utils                       \
    python3-bibtexparser                \
    python3-breathe                     \
    python3-git                         \
    python3-github                      \
    python3-junitxml                    \
    python3-natsort                     \
    python3-pip                         \
    python3-simplejson                  \
    python3-sphinx                      \
    python3-sphinxcontrib.bibtex        \
    python3-sphinxcontrib.programoutput \
    python3-svgwrite                    \
    python3-venv                        \
    qt6-base-dev                        \
    qt6-scxml-dev                       \
    qt6-tools-dev                       \
    qt6-tools-dev-tools                 \
    qt6-webengine-dev                   \
    qtwebengine5-dev                    \
    subversion                          \
    texlive-base                        \
    texlive-bibtex-extra                \
    texlive-lang-greek                  \
    texlive-latex-extra                 \
    unzip                               \
    wget                                \
    xsltproc                            \
    xvfb                                \
    zip                                 \
  && apt-get clean                      \
  && rm -rf /var/lib/apt/lists/*

# Python default virtual environment, OMPython
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir ompython==3.6.0

# Set locale
ENV LANGUAGE=en_US:en
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
