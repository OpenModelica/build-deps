# OpenModelica build-deps Docker Image

[![Build Docker Image](https://github.com/OpenModelica/build-deps/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/OpenModelica/build-deps/actions/workflows/build.yml)
[![Publish Docker Image](https://github.com/OpenModelica/build-deps/actions/workflows/publish.yml/badge.svg)](https://github.com/OpenModelica/build-deps/actions/workflows/publish.yml)

The Docker images used to build and deploy
[OpenModelica](https://github.com/OpenModelica/OpenModelica) with
[Jenkins](https://test.openmodelica.org/jenkins/).

## Build

```bash
export TAG=v1.21.3
docker build --pull --no-cache --tag build-deps:$TAG .
```

## Upload

The [publish.yml](./.github/workflows/publish.yml) workflow will build and upload the
Docker image to [openmodelica/build-deps](https://hub.docker.com/repository/docker/openmodelica/build-deps)
for each release.

To do it manually run:

```bash
export REGISTRY=openmodelica
export TAG=v1.21.3
docker login
docker image tag build-deps:$TAG $REGISTRY/build-deps:$TAG
docker push $REGISTRY/build-deps:$TAG
```

## License

See [LICENSE.md](./LICENSE.md).
