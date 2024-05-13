# OpenModelica build-deps Docker Image

[![Build Docker Image](https://github.com/OpenModelica/build-deps/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/OpenModelica/build-deps/actions/workflows/build.yml)
[![Publish Docker Image](https://github.com/OpenModelica/build-deps/actions/workflows/publish.yml/badge.svg)](https://github.com/OpenModelica/build-deps/actions/workflows/publish.yml)

The Docker images used to build and deploy
[OpenModelica](https://github.com/OpenModelica/OpenModelica) with
[Jenkins](https://test.openmodelica.org/jenkins/).

## Structure of the Repository

Each minor version of the Dockerfile corresponds to a OpenModelica minor version
and has its own branch. Each branch has tags for each patch version.

When creating a release from a tag the [workflow](./.github/workflows/publish.yml) will
publish the Docker image to [openmodelica/build-deps](https://hub.docker.com/repository/docker/openmodelica/build-deps).

### Ubuntu based Images

  - 24.04 Noble: [releases/v1.23](https://github.com/OpenModelica/build-deps/tree/releases/v1.23)
  - 22.04 Jammy + QT web engine: [releases/v1.22-qtwebengine](https://github.com/OpenModelica/build-deps/tree/releases/v1.22-qtwebengine)
  - 22.04 Jammy: [releases/v1.22](https://github.com/OpenModelica/build-deps/tree/releases/v1.22)
  - 20.04 Focal: [releases/v1.21](https://github.com/OpenModelica/build-deps/tree/releases/v1.21)
  - 18.04 Bionic + cmake: [releases/v1.16-cmake](https://github.com/OpenModelica/build-deps/tree/releases/v1.16-cmake)
  - 18.04 Bionic: [releases/v1.16](https://github.com/OpenModelica/build-deps/tree/releases/v1.16)

## Build

```bash
export TAG=v1.23.0-wip
docker build --pull --no-cache --tag build-deps:$TAG .
```

## Upload

The [publish.yml](./.github/workflows/publish.yml) workflow will build and upload the
Docker image to [openmodelica/build-deps](https://hub.docker.com/repository/docker/openmodelica/build-deps)
for each release.

To do it manually run:

```bash
export REGISTRY=openmodelica
export TAG=v1.23.0-wip
docker login
docker image tag build-deps:$TAG $REGISTRY/build-deps:$TAG
docker push $REGISTRY/build-deps:$TAG
```

## License

See [LICENSE.md](./LICENSE.md).
