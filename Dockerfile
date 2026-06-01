FROM ubuntu:jammy

# Image / OCI metadata
LABEL maintainer="AnHeuermann"
LABEL description="OpenModelica build-deps Docker Image "
LABEL organization="OpenModelica"

LABEL org.opencontainers.image.vendor="OpenModelica"
LABEL org.opencontainers.image.authors="AnHeuermann"
LABEL org.opencontainers.image.version="v1.22.3"
LABEL org.opencontainers.image.description="OpenModelica build-deps Docker Image "
LABEL org.opencontainers.image.source="https://github.com/OpenModelica/build-deps"
LABEL org.opencontainers.image.license="MIT"

ENV SHELL=/bin/bash

# Ensure DEBIAN_FRONTEND is only set during build
ARG DEBIAN_FRONTEND=noninteractive

# Install build-deps of OpenModelica
RUN apt-get update                                                                                                                          \
  && apt-get upgrade -qy                                                                                                                    \
  && apt-get dist-upgrade -qy                                                                                                               \
  && apt-get install -qy                                                                                                                    \
    ca-certificates                                                                                                                         \
    curl                                                                                                                                    \
    gnupg                                                                                                                                   \
    lsb-release                                                                                                                             \
  && curl -fsSL https://build.openmodelica.org/apt/openmodelica-2026.asc | gpg --dearmor -o /usr/share/keyrings/openmodelica-keyring.gpg    \
  && echo                                                                                                                                   \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/openmodelica-keyring.gpg] https://build.openmodelica.org/apt      \
    $(cat /etc/os-release | grep "\(UBUNTU\\|DEBIAN\\|VERSION\)_CODENAME" | sort | cut -d= -f 2 | head -1)                                  \
    nightly" | tee /etc/apt/sources.list.d/openmodelica.list > /dev/null                                                                    \
  && echo                                                                                                                                   \
    "deb-src [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/openmodelica-keyring.gpg] https://build.openmodelica.org/apt  \
    $(cat /etc/os-release | grep "\(UBUNTU\\|DEBIAN\\|VERSION\)_CODENAME" | sort | cut -d= -f 2 | head -1)                                  \
    nightly" | tee -a /etc/apt/sources.list.d/openmodelica.list > /dev/null                                                                 \
  && apt-get update                                                                                                                         \
  && apt-get build-dep -qy openmodelica

# Install additional dependencies, e.g. to build the User's Guide
RUN apt-get install -qy \
  aspell                \
  bibtex2html           \
  bison                 \
  ccache                \
  clang-tools           \
  devscripts            \
  docker.io             \
  doxygen               \
  equivs                \
  flex                  \
  git                   \
  gnuplot-nox           \
  inkscape              \
  intel-opencl-icd      \
  latexmk               \
  libcurl4-gnutls-dev   \
  libmldbm-perl         \
  ocl-icd-opencl-dev    \
  opencl-headers        \
  pandoc                \
  pocl-opencl-icd       \
  poppler-utils         \
  python3-pip           \
  qtwebengine5-dev      \
  subversion            \
  texlive-base          \
  texlive-bibtex-extra  \
  texlive-lang-greek    \
  texlive-latex-extra   \
  unzip                 \
  wget                  \
  xsltproc              \
  xvfb                  \
  zip

RUN wget https://raw.githubusercontent.com/OpenModelica/OpenModelicaBuildScripts/master/debian/control \
  && mk-build-deps --install -t 'apt-get --force-yes -y' control

# Python packages
RUN wget https://raw.githubusercontent.com/OpenModelica/OpenModelica/master/doc/UsersGuide/source/requirements.txt \
  && pip3 install --no-cache-dir --upgrade -r requirements.txt \
  && pip3 install --no-cache-dir --upgrade junit_xml simplejson svgwrite PyGithub

# Set locale
ENV LANGUAGE=en_US:en
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
RUN apt-get install -qy locales

# Clean
RUN rm -rf /var/lib/apt/lists/* \
  && apt-get clean \
  && rm -f control requirements.txt *.deb \
  && rm /openmodelica-build-deps_1.0_amd64.buildinfo /openmodelica-build-deps_1.0_amd64.changes
