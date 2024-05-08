# OpenModelica build-deps Docker Image

[![Build v1.16](https://github.com/OpenModelica/build-deps/actions/workflows/build.yml/badge.svg?branch=releases%2Fv1.16)](https://github.com/OpenModelica/build-deps/actions/workflows/build.yml)
[![Publish v1.16](https://github.com/OpenModelica/build-deps/actions/workflows/publish.yml/badge.svg?branch=releases%2Fv1.16)](https://github.com/OpenModelica/build-deps/actions/workflows/publish.yml)

The Docker image used to build and deploy
[OpenModelica](https://github.com/OpenModelica/OpenModelica) with
[Jenkins](https://test.openmodelica.org/jenkins/).

## Build

```bash
export TAG=v1.16.5-cmake
docker build --pull --no-cache --tag build-deps:$TAG .
```

## Upload

The [publish.yml](./.github/workflows/publish.yml) workflow will build and upload the
Docker image to [openmodelica/build-deps](https://hub.docker.com/repository/docker/openmodelica/build-deps)
for each release.

Otherwise run:

```bash
export REGISTRY=openmodelica
export TAG=v1.16.5-cmake
docker login
docker image tag build-deps:$TAG $REGISTRY/build-deps:$TAG
docker push $REGISTRY/build-deps:$TAG
```

## License

The Dockerfile is taken from [https://github.com/OpenModelica/OpenModelicaBuildScripts](OpenModelica/OpenModelicaBuildScripts).
No idea what license applies...
