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

# Install OpenModelica GPG key
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
  && apt-get update

# Install Debian build deps
RUN apt-get install -qy                                                                                                                   \
    wget                                                                                                                                  \
    devscripts                                                                                                                            \
    equivs                                                                                                                                \
  && wget https://raw.githubusercontent.com/OpenModelica/OpenModelicaBuildScripts/37b564c1674023a5afb7517e408ffd9bd174a59c/debian/control \
  && mk-build-deps --install -t 'apt-get --force-yes -y' control

# Install additional dependencies, e.g. to build the User's Guide
RUN apt-get install -qy                                                        \
  aspell                                                                       \
  bibtex2html                                                                  \
  bison                                                                        \
  ccache                                                                       \
  clang-tools                                                                  \
  docker.io                                                                    \
  doxygen                                                                      \
  flex                                                                         \
  git                                                                          \
  gnuplot-nox                                                                  \
  inkscape                                                                     \
  intel-opencl-icd                                                             \
  latexmk                                                                      \
  libcurl4-gnutls-dev                                                          \
  libmldbm-perl                                                                \
  ocl-icd-opencl-dev                                                           \
  opencl-headers                                                               \
  pandoc                                                                       \
  pocl-opencl-icd                                                              \
  poppler-utils                                                                \
  python3-pip                                                                  \
  qttools5-dev                                                                 \
  qtwebengine5-dev                                                             \
  subversion                                                                   \
  texlive-base                                                                 \
  texlive-bibtex-extra                                                         \
  texlive-lang-greek                                                           \
  texlive-latex-extra                                                          \
  unzip                                                                        \
  xsltproc                                                                     \
  xvfb                                                                         \
  zip

# Qt6 tools
RUN apt-get install -qy                                                        \
  libqt6concurrent6                                                            \
  libqt6core5compat6                                                           \
  libqt6core5compat6-dev                                                       \
  libqt6core6                                                                  \
  libqt6dbus6                                                                  \
  libqt6designer6                                                              \
  libqt6designercomponents6                                                    \
  libqt6gui6                                                                   \
  libqt6help6                                                                  \
  libqt6labsanimation6                                                         \
  libqt6labsfolderlistmodel6                                                   \
  libqt6labsqmlmodels6                                                         \
  libqt6labssettings6                                                          \
  libqt6labssharedimage6                                                       \
  libqt6labswavefrontmesh6                                                     \
  libqt6network6                                                               \
  libqt6opengl6                                                                \
  libqt6opengl6-dev                                                            \
  libqt6openglwidgets6                                                         \
  libqt6pdf6                                                                   \
  libqt6pdfquick6                                                              \
  libqt6pdfwidgets6                                                            \
  libqt6positioning6                                                           \
  libqt6positioning6-plugins                                                   \
  libqt6positioningquick6                                                      \
  libqt6printsupport6                                                          \
  libqt6qml6                                                                   \
  libqt6qmlcore6                                                               \
  libqt6qmllocalstorage6                                                       \
  libqt6qmlmodels6                                                             \
  libqt6qmlworkerscript6                                                       \
  libqt6qmlxmllistmodel6                                                       \
  libqt6quick6                                                                 \
  libqt6quickcontrols2-6                                                       \
  libqt6quickcontrols2impl6                                                    \
  libqt6quickdialogs2-6                                                        \
  libqt6quickdialogs2quickimpl6                                                \
  libqt6quickdialogs2utils6                                                    \
  libqt6quicklayouts6                                                          \
  libqt6quickparticles6                                                        \
  libqt6quickshapes6                                                           \
  libqt6quicktemplates2-6                                                      \
  libqt6quicktest6                                                             \
  libqt6quickwidgets6                                                          \
  libqt6serialport6                                                            \
  libqt6sql6                                                                   \
  libqt6sql6-sqlite                                                            \
  libqt6svg6                                                                   \
  libqt6svg6-dev                                                               \
  libqt6svgwidgets6                                                            \
  libqt6test6                                                                  \
  libqt6uitools6                                                               \
  libqt6waylandclient6                                                         \
  libqt6waylandcompositor6                                                     \
  libqt6waylandeglclienthwintegration6                                         \
  libqt6waylandeglcompositorhwintegration6                                     \
  libqt6webchannel6                                                            \
  libqt6webchannel6-dev                                                        \
  libqt6webengine6-data                                                        \
  libqt6webenginecore6                                                         \
  libqt6webenginecore6-bin                                                     \
  libqt6webenginequick6                                                        \
  libqt6webenginequickdelegatesqml6                                            \
  libqt6webenginewidgets6                                                      \
  libqt6webview6                                                               \
  libqt6webviewquick6                                                          \
  libqt6widgets6                                                               \
  libqt6wlshellintegration6                                                    \
  libqt6xml6                                                                   \
  qt6-base-dev                                                                 \
  qt6-base-dev-tools                                                           \
  qt6-declarative-dev                                                          \
  qt6-declarative-dev-tools                                                    \
  qt6-l10n-tools                                                               \
  qt6-tools-dev                                                                \
  qt6-tools-dev-tools                                                          \
  qt6-translations-l10n                                                        \
  qt6-webengine-dev                                                            \
  qt6-webengine-dev-tools                                                      \
  qt6-webview-dev                                                              \
  qt6-webview-plugins

# Python packages
RUN pip3 install --no-cache-dir                                                \
    junit_xml                                                                  \
    ompython==3.6.0                                                            \
    PyGithub                                                                   \
    simplejson                                                                 \
    svgwrite                                                                   \
  && pip3 install --no-cache-dir -r                                            \
    https://raw.githubusercontent.com/OpenModelica/OpenModelica/9c0dc9a8ab50ba652109584cb3fecaef86640b66/doc/UsersGuide/source/requirements.txt

# Set locale
ENV LANGUAGE=en_US:en
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
RUN apt-get install -qy locales

# Clean
RUN rm -rf /var/lib/apt/lists/* \
  && apt-get clean \
  && rm -f control *.deb \
  && rm /openmodelica-build-deps_1.0_amd64.buildinfo /openmodelica-build-deps_1.0_amd64.changes
