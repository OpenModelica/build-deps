#!/usr/bin/env python3
"""Helpers for the CI.

Reads ``.ci/matrix.yml`` (the single source of truth for which images exist)
and answers questions for the GitHub Actions workflows:

    matrix.py all
        Print, on one line, a JSON array of every image. Used as the
        ``strategy.matrix`` for the build workflow. Each element looks like::

            {"os": "ubuntu", "version": "24.04", "dir": "ubuntu/24.04",
             "base_tag": "ubuntu-24.04", "context": "ubuntu",
             "dockerfile": "ubuntu/Dockerfile", "target": "full",
             "build_args": "UBUNTU_VERSION=24.04", "addons": "cmake-4"}

        ``target`` is the build stage for the base image ("" = final stage).
        Each add-on in ``addons`` is itself a build stage (--target). Both
        ``build_args`` and ``addons`` are space-separated strings so they can be
        looped over in shell directly.

    matrix.py image <tag>
        Resolve a per-image tag such as ``ubuntu-24.04-2.1.0`` (synthesized
        from the global ``v2.1.0`` release tag by ``publish-matrix``) to the
        image it refers to and print shell ``key='value'`` assignments::

            dir='ubuntu/24.04'
            base_tag='ubuntu-24.04'
            semver='2.1.0'
            context='apt'
            dockerfile='apt/Dockerfile'
            target='full'
            build_args='DISTRO=ubuntu VERSION=24.04'
            addons='cmake-4'

        Intended to be consumed with ``eval "$(python .ci/matrix.py image …)"``.

    matrix.py publish-matrix [<semver>]
        Print, on one line, a JSON array of publish-job descriptors for every
        image in the matrix.

        Without ``<semver>``: returns moving-tag-only descriptors (used when
        publishing from ``main`` or the scheduled rebuild)::

            [{"tag":"ubuntu-24.04"},{"tag":"ubuntu-22.04"}]

        With ``<semver>``: returns immutable-tag descriptors synthesized from a
        global release tag such as ``v2.1.0`` (pass the version without the
        leading ``v``)::

            [{"tag":"ubuntu-24.04-2.1.0"},{"tag":"ubuntu-22.04-2.1.0"}]
"""

from __future__ import annotations

import json
import os
import re
import shlex
import sys

import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
MATRIX_FILE = os.path.join(HERE, "matrix.yml")

SEMVER_RE = re.compile(r"^(?P<prefix>.+)-(?P<semver>\d+\.\d+\.\d+|[a-z][a-z0-9-]*)$")


def load_images():
    with open(MATRIX_FILE, encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    images = data.get("images") or []
    result = []
    for img in images:
        os_name = str(img["os"])
        version = str(img["version"])
        directory = f"{os_name}/{version}"
        context = str(img.get("context") or f"{directory}/base")
        dockerfile = str(img.get("dockerfile") or f"{context}/Dockerfile")
        target = str(img.get("target") or "")
        build_args = " ".join(
            f"{k}={v}" for k, v in (img.get("build_args") or {}).items()
        )
        addons = [str(a) for a in (img.get("addons") or [])]
        result.append(
            {
                "os": os_name,
                "version": version,
                "dir": directory,
                "base_tag": f"{os_name}-{version}",
                "context": context,
                "dockerfile": dockerfile,
                "target": target,
                "build_args": build_args,
                "addons": " ".join(addons),
            }
        )
    return result


def cmd_all():
    print(json.dumps(load_images(), separators=(",", ":")))


def cmd_publish_matrix(semver: str | None = None):
    images = load_images()
    if semver is None:
        result = [{"tag": img["base_tag"]} for img in images]
    else:
        result = [{"tag": f"{img['base_tag']}-{semver}"} for img in images]
    print(json.dumps(result, separators=(",", ":")))


def cmd_image(tag: str):
    images = load_images()

    # Exact base-tag match → moving-only publish (no semver).
    for img in images:
        if img["base_tag"] == tag:
            print(f"dir={shlex.quote(img['dir'])}")
            print(f"base_tag={shlex.quote(img['base_tag'])}")
            print(f"semver=''")
            print(f"context={shlex.quote(img['context'])}")
            print(f"dockerfile={shlex.quote(img['dockerfile'])}")
            print(f"target={shlex.quote(img['target'])}")
            print(f"build_args={shlex.quote(img['build_args'])}")
            print(f"addons={shlex.quote(img['addons'])}")
            return

    match = SEMVER_RE.match(tag)
    if not match:
        valid = ", ".join(img["base_tag"] for img in images)
        sys.exit(
            f"error: tag '{tag}' is not a known base tag and is not of the form "
            f"<os>-<version>-<semver> (e.g. ubuntu-24.04 or ubuntu-24.04-2.1.0). "
            f"Known base tags: {valid}"
        )
    prefix = match.group("prefix")
    semver = match.group("semver")

    for img in images:
        if img["base_tag"] == prefix:
            print(f"dir={shlex.quote(img['dir'])}")
            print(f"base_tag={shlex.quote(img['base_tag'])}")
            print(f"semver={shlex.quote(semver)}")
            print(f"context={shlex.quote(img['context'])}")
            print(f"dockerfile={shlex.quote(img['dockerfile'])}")
            print(f"target={shlex.quote(img['target'])}")
            print(f"build_args={shlex.quote(img['build_args'])}")
            print(f"addons={shlex.quote(img['addons'])}")
            return

    valid = ", ".join(img["base_tag"] for img in images)
    sys.exit(
        f"error: no image matches tag prefix '{prefix}'. "
        f"Known images: {valid}"
    )


def main(argv):
    if len(argv) >= 2 and argv[1] == "all":
        cmd_all()
    elif len(argv) >= 3 and argv[1] == "image":
        cmd_image(argv[2])
    elif len(argv) >= 2 and argv[1] == "publish-matrix":
        cmd_publish_matrix(argv[2] if len(argv) >= 3 else None)
    else:
        sys.exit(f"usage: {argv[0]} all | image <tag> | publish-matrix [<semver>]")


if __name__ == "__main__":
    main(sys.argv)
