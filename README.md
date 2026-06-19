# OpenModelica build-deps Docker Image

[![Build Docker Image](https://github.com/OpenModelica/build-deps/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/OpenModelica/build-deps/actions/workflows/build.yml)
[![Publish Docker Image](https://github.com/OpenModelica/build-deps/actions/workflows/publish.yml/badge.svg)](https://github.com/OpenModelica/build-deps/actions/workflows/publish.yml)

The Docker images used to build and deploy
[OpenModelica](https://github.com/OpenModelica/OpenModelica) with
[Jenkins](https://test.openmodelica.org/jenkins/).

## Build

```bash
export TAG=v1.22.4
docker build --pull --no-cache --tag build-deps:$TAG .
```

## Upload

The [publish.yml](./.github/workflows/publish.yml) workflow will build, sign and
upload the Docker image to
[GitHub Container registry](https://github.com/OpenModelica/openmodelica-build-deps/pkgs/container/build-deps)
for each release.

## License

The original Dockerfile was taken from
[OpenModelica/OpenModelicaBuildScripts](https://github.com/OpenModelica/OpenModelicaBuildScripts).
See [LICENSE.md](./LICENSE.md).
