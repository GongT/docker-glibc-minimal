#!/usr/bin/env bash

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

podman run --rm -it \
	"--volume=/var/lib/dnf/repos:/var/lib/dnf/repos" \
	"--volume=/var/cache/dnf:/var/cache/dnf" \
	"--volume=$(pwd):/root" \
	fedora \
	bash
