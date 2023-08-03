# OpenModelica build-deps Docker Image

[![Build Docker Image](https://github.com/AnHeuermann/build-deps/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/AnHeuermann/build-deps/actions/workflows/build.yml)
[![Publish Docker Image](https://github.com/AnHeuermann/build-deps/actions/workflows/publish.yml/badge.svg)](https://github.com/AnHeuermann/build-deps/actions/workflows/publish.yml)

The Docker image used to build and deploy
[OpenModelica](https://github.com/OpenModelica/OpenModelica) with
Jenkins[https://test.openmodelica.org/jenkins/].

## Build

```bash
export TAG=v1.22.0
docker build --pull --no-cache --tag build-deps:$TAG .
```

## Upload

The [publish.yml](./.github/workflows/publish.yml) workflow will build and upload the
Docker image to [https://hub.docker.com/repository/docker/anheuermann/openmodelica-build-deps](anheuermann/openmodelica-build-deps)
for each release.

Otherwise run:

```bash
export REGISTRY=anheuermann
export TAG=v1.22.0
docker login
docker image tag build-deps:$TAG $REGISTRY/build-deps:$TAG
docker push $REGISTRY/build-deps:$TAG
```

## License

The original Dockerfile are taken from [https://github.com/OpenModelica/OpenModelicaBuildScripts](OpenModelica/OpenModelicaBuildScripts).
See [LICENSE.md](./LICENSE.md).
