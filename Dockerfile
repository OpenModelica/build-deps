FROM ubuntu:jammy

LABEL org.opencontainers.image.authors="AnHeuermann"

ENV SHELL /bin/bash

# Non-root user
ARG USERNAME=openmodelica-user

# Ensure DEBIAN_FRONTEND is only set during build
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -qy && apt-get dist-upgrade -qy
RUN apt-get install -qy \
  ca-certificates       \
  curl                  \
  gnupg

# Install build-deps of OpenModelica
RUN curl -fsSL http://build.openmodelica.org/apt/openmodelica.asc | gpg --dearmor -o /usr/share/keyrings/openmodelica-keyring.gpg
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/openmodelica-keyring.gpg] https://build.openmodelica.org/apt \
  jammy nightly" | tee /etc/apt/sources.list.d/openmodelica.list > /dev/null
RUN echo \
  "deb-src [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/openmodelica-keyring.gpg] https://build.openmodelica.org/apt \
  jammy nightly " | tee -a /etc/apt/sources.list.d/openmodelica.list > /dev/null
RUN apt-get update && apt-get build-dep -qy openmodelica

# Install additional dependencies, e.g. to build the User's Guide
RUN apt-get install -qy \
  aspell                \
  bibtex2html           \
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
ENV LANGUAGE en_US:en
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
RUN apt-get install -qy locales

# Clean
RUN rm -rf /var/lib/apt/lists/* \
  && apt-get clean \
  && rm -f control requirements.txt *.deb \
  && rm /build-deps_1.0_amd64.buildinfo /build-deps_1.0_amd64.changes

# Create non-root user
RUN useradd -m $USERNAME

ENV USER=$USERNAME
USER $USERNAME
