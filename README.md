# OpenModelica build-deps Docker Image

[![Build v1.16-cmake](https://github.com/AnHeuermann/build-deps/actions/workflows/build.yml/badge.svg?branch=releases%2Fv1.16-cmake)](https://github.com/AnHeuermann/build-deps/actions/workflows/build.yml)

The Docker image used to build and deploy
[OpenModelica](https://github.com/OpenModelica/OpenModelica) with
Jenkins[https://test.openmodelica.org/jenkins/].

## Build

```bash
export TAG=v1.16.3-cmake
docker build --pull --no-cache --tag build-deps:$TAG .
```

## Upload

The [publish.yml](./.github/workflows/publish.yml) workflow will build and upload the
Docker image to [https://hub.docker.com/repository/docker/anheuermann/openmodelica-build-deps](anheuermann/openmodelica-build-deps)
for each release.

Otherwise run:

```bash
export REGISTRY=anheuermann
export TAG=v1.16.3-cmake
docker login
docker image tag build-deps:$(VERSION) $(REGISTRY)/build-deps:$TAG
```

## License

The Dockerfile is taken from [https://github.com/OpenModelica/OpenModelicaBuildScripts](OpenModelica/OpenModelicaBuildScripts).
No idea what license applies...
