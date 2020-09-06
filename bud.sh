#!/usr/bin/env bash

set -Eeuo pipefail

echo -ne "\ec"

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
cd docker

function bud() {
	local tag="$1"
	buildah bud \
		"--volume=/var/lib/dnf/repos:/var/lib/dnf/repos" \
		"--volume=/var/cache/dnf:/var/cache/dnf" \
		"--tag=docker.io/gongt/busybox-glibc:$tag" \
		"$tag.dockerfile"
}

bud bash
bud busybox
bud latest
