FROM ubuntu:focal

ARG OCL=16.1.2_x64_rh_6.4.0.37
# Ensure DEBIAN_FRONTEND is only set during build
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -qy && apt-get dist-upgrade -qy
RUN apt-get install -qy \
      gnupg wget ca-certificates apt-transport-https
RUN apt-get install -qy \
      aspell \
      bibtex2html \
      cpio \
      devscripts \
      docker.io \
      doxygen \
      equivs \
      flex \
      g++ \
      git \
      gnuplot-nox \
      inkscape \
      intel-opencl-icd \
      latexmk \
      libcurl4-gnutls-dev \
      libmldbm-perl \
      ocl-icd-opencl-dev \
      pandoc \
      pocl-opencl-icd \
      poppler-utils \
      python3-pip \
      subversion \
      sudo \
      texlive-base \
      texlive-lang-greek \
      texlive-latex-extra \
      unzip \
      xsltproc \
      xvfb \
      zip

RUN wget https://raw.githubusercontent.com/OpenModelica/OpenModelicaBuildScripts/master/debian/control \
    && mk-build-deps --install -t 'apt-get --force-yes -y' control

# Python packages
RUN wget https://raw.githubusercontent.com/OpenModelica/OpenModelica/master/doc/UsersGuide/source/requirements.txt \
    && pip3 install --no-cache-dir --upgrade -r requirements.txt \
    && pip3 install --no-cache-dir --upgrade junit_xml simplejson svgwrite PyGithub

# Clean
RUN rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && rm -f control requirements.txt *.deb
