#!/usr/bin/env python3
"""Helpers for the CI.

Reads ``.ci/matrix.yml`` (the single source of truth for which images exist)
and answers questions for the GitHub Actions workflows:

    matrix.py all
        Print, on one line, a JSON array of every image. Used as the
        ``strategy.matrix`` for the build workflow. Each element looks like::

            {"os": "ubuntu", "version": "24.04", "base_tag": "ubuntu-24.04"}

        The recipe of an image (context, Dockerfile, stages, build-args) is
        looked up from its base tag by ``matrix.py image``.

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
    result = [
        {"os": img["os"], "version": img["version"], "base_tag": img["base_tag"]}
        for img in load_images()
    ]
    print(json.dumps(result, separators=(",", ":")))


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


def _dockerfile_stages(path):
    """Stages of a Dockerfile as (name, instructions, dependencies), in file
    order, plus the global ARG lines preceding the first FROM.

    Docker strips comment lines before joining continuations, so they are
    dropped first; a bare `#` line inside a RUN is a comment, not shell input.
    """
    logical = []
    pending = ""
    for raw in open(path, encoding="utf-8").read().split("\n"):
        if raw.lstrip().startswith("#"):
            continue
        pending += raw
        if pending.rstrip().endswith("\\"):
            pending = pending.rstrip()[:-1]
            continue
        if pending.strip():
            logical.append(" ".join(pending.split()))
        pending = ""
    if pending.strip():
        logical.append(" ".join(pending.split()))

    globals_, stages, current = [], [], None
    for line in logical:
        from_match = re.match(
            r"FROM\s+(?:--\S+\s+)*(\S+)(?:\s+AS\s+(\S+))?$", line, re.IGNORECASE
        )
        if from_match:
            base = from_match.group(1).lower()
            name = (from_match.group(2) or f"<stage{len(stages)}>").lower()
            current = {"name": name, "base": base, "lines": [line], "deps": {base}}
            stages.append(current)
            continue
        if current is None:
            if re.match(r"ARG\s", line, re.IGNORECASE):
                globals_.append(line)
            continue
        current["lines"].append(line)
        current["deps"].update(m.lower() for m in re.findall(r"--from=(\S+)", line))
        current["deps"].update(
            m.lower() for m in re.findall(r"--mount=\S*?from=([A-Za-z0-9_.-]+)", line)
        )
    return globals_, stages


def cmd_recipe(dockerfile: str, target: str):
    """The instructions building `target` would run, and nothing else.

    Everything reachable from the target stage through FROM and --from=, so an
    edit to one stage only invalidates that stage and its descendants instead of
    every image the Dockerfile serves.
    """
    globals_, stages = _dockerfile_stages(dockerfile)
    by_name = {stage["name"]: stage for stage in stages}
    target = target.lower()
    if target not in by_name:
        # No such stage: the target is the last stage (docker's default).
        if target:
            sys.exit(
                f"error: {dockerfile} has no stage '{target}'. "
                f"Stages: {', '.join(s['name'] for s in stages)}"
            )
        target = stages[-1]["name"]

    needed, queue = set(), [target]
    while queue:
        name = queue.pop()
        if name in needed:
            continue
        needed.add(name)
        queue.extend(dep for dep in by_name[name]["deps"] if dep in by_name)

    print(f"target={target}")
    for line in globals_:
        print(line)
    for stage in stages:
        if stage["name"] in needed:
            print(f"# stage {stage['name']}")
            print("\n".join(stage["lines"]))


def cmd_parent(dockerfile: str, stage: str):
    """The stage `stage` is FROM, when that is another stage of this Dockerfile.

    Prints nothing when the stage builds on an external image, which is what
    tells the caller there is no published parent image to build on top of.
    """
    _, stages = _dockerfile_stages(dockerfile)
    by_name = {s["name"]: s for s in stages}
    stage = stage.lower()
    if stage not in by_name:
        sys.exit(
            f"error: {dockerfile} has no stage '{stage}'. "
            f"Stages: {', '.join(s['name'] for s in stages)}"
        )
    base = by_name[stage]["base"]
    if base in by_name:
        print(base)


def main(argv):
    if len(argv) >= 2 and argv[1] == "all":
        cmd_all()
    elif len(argv) >= 3 and argv[1] == "image":
        cmd_image(argv[2])
    elif len(argv) >= 2 and argv[1] == "publish-matrix":
        cmd_publish_matrix(argv[2] if len(argv) >= 3 else None)
    elif len(argv) >= 4 and argv[1] == "recipe":
        cmd_recipe(argv[2], argv[3])
    elif len(argv) >= 4 and argv[1] == "parent":
        cmd_parent(argv[2], argv[3])
    else:
        sys.exit(
            f"usage: {argv[0]} all | image <tag> | publish-matrix [<semver>] "
            f"| recipe <dockerfile> <stage> | parent <dockerfile> <stage>"
        )


if __name__ == "__main__":
    main(sys.argv)
