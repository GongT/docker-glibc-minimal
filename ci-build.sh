#!/usr/bin/env bash

set -Eeuo pipefail

export TAG=$1
export TMPDIR="$RUNNER_TEMP"
export REWRITE_IMAGE_NAME="build.local/dist/${TAG}"

export REGISTRY_AUTH_FILE="$HOME/secrets/auth.json"

echo "REGISTRY_AUTH_FILE=${REGISTRY_AUTH_FILE}" >>"$GITHUB_ENV"
echo "SYSTEM_COMMON_CACHE=${SYSTEM_COMMON_CACHE:=$HOME/cache}" >>"$GITHUB_ENV"

mkdir -p "$HOME/secrets"
echo '{}' >"$REGISTRY_AUTH_FILE"

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=../common/functions-build-host.sh
source "./common/functions-build-host.sh"

if [[ ${CI+found} != found ]]; then
	die "This script is only for CI"
fi

sudo bash "./build.sh" "$TAG" || die "Build failed"
