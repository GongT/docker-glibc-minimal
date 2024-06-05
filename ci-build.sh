#!/usr/bin/env bash

set -Eeuo pipefail

export TAG=$1
export TMPDIR="$RUNNER_TEMP"
export REWRITE_IMAGE_NAME="build.local/dist/${TAG}"

export REGISTRY_AUTH_FILE="$HOME/secrets/auth.json"
export SYSTEM_COMMON_CACHE="$HOME/cache"

echo "REGISTRY_AUTH_FILE=${REGISTRY_AUTH_FILE}" >>"$GITHUB_ENV"
echo "SYSTEM_COMMON_CACHE=${SYSTEM_COMMON_CACHE}" >>"$GITHUB_ENV"

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=../common/functions-build-host.sh
source "./common/functions-build-host.sh"

if [[ ${CI+found} != found ]]; then
	die "This script is only for CI"
fi

mkdir -p "$HOME/secrets"
echo '{}' >"$REGISTRY_AUTH_FILE"

export DIST_FOLDER="$(mktemp -d)"
export SOURCE_FOLDER="$(mktemp -d)"

sudo --preserve-env bash "./build.sh" "$TAG" || die "Build failed"
