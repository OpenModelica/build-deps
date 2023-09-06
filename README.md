# OpenModelica build-deps Docker Image

[![Build Docker Image](https://github.com/AnHeuermann/build-deps/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/AnHeuermann/build-deps/actions/workflows/build.yml)
[![Publish Docker Image](https://github.com/AnHeuermann/build-deps/actions/workflows/publish.yml/badge.svg)](https://github.com/AnHeuermann/build-deps/actions/workflows/publish.yml)

The Docker image used to build and deploy
[OpenModelica](https://github.com/OpenModelica/OpenModelica) with
[Jenkins](https://test.openmodelica.org/jenkins/).

## Structure of the Repository

Each minor version of the Dockerfile corresponds to a OpenModelica minor version and has
its own branch.
Each branch has tags for each patch version.

When creating a release form a tag the [workflow](./.github/workflows/publish.yml) will
publish the Docker image to [https://hub.docker.com/repository/docker/anheuermann/openmodelica-build-deps](anheuermann/openmodelica-build-deps).

### Ubuntu based Images

  - 22.04 Jammy: [releases/v1.22](https://github.com/AnHeuermann/build-deps/tree/releases/v1.22)
  - 20.04 Focal: [releases/v1.21](https://github.com/AnHeuermann/build-deps/tree/releases/v1.21)
  - 18.04 Bionic + cmake: [releases/v1.16-cmake](https://github.com/AnHeuermann/build-deps/tree/releases/v1.16-cmake)
  - 18.04 Bionic: [releases/v1.16](https://github.com/AnHeuermann/build-deps/tree/releases/v1.16)

### Debian based Images

  - 12 Bookworm
  - 11 Bullseye

### CentOS based Images

  - CentOS7


## Build

```bash
export TAG=v1.22.1
docker build --pull --no-cache --tag build-deps:$TAG .
```

or

```bash
export TAG=v1.22.1
docker build --pull --no-cache --squash --tag build-deps:$TAG .
```

to reduce image size.

## Upload

The [publish.yml](./.github/workflows/publish.yml) workflow will build and upload the
Docker image to [https://hub.docker.com/repository/docker/anheuermann/openmodelica-build-deps](anheuermann/openmodelica-build-deps)
for each release.

To upload to docker.openmodelica.org (you'll need write access) run:

```bash
export REGISTRY=docker.openmodelica.org
export TAG=v1.22.1
docker login
docker image tag build-deps:$TAG $REGISTRY/build-deps:$TAG
docker push $REGISTRY/build-deps:$TAG
```

## License

The original Dockerfile are taken from [https://github.com/OpenModelica/OpenModelicaBuildScripts](OpenModelica/OpenModelicaBuildScripts).
See [LICENSE.md](./LICENSE.md).
