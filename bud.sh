#!/usr/bin/env bash

set -Eeuo pipefail

echo -ne "\ec"

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
cd docker

buildah bud \
	"--volume=/var/lib/dnf/repos:/var/lib/dnf/repos" \
	"--volume=/var/cache/dnf:/var/cache/dnf" \
	"--tag=docker.io/gongt/busybox-glibc:bash" \
	bash.dockerfile

buildah bud \
	"--volume=/var/lib/dnf/repos:/var/lib/dnf/repos" \
	"--volume=/var/cache/dnf:/var/cache/dnf" \
	"--tag=docker.io/gongt/busybox-glibc:busybox" \
	busybox.dockerfile

buildah bud \
	"--volume=/var/lib/dnf/repos:/var/lib/dnf/repos" \
	"--volume=/var/cache/dnf:/var/cache/dnf" \
	"--tag=docker.io/gongt/busybox-glibc" \
	minimal.dockerfile
