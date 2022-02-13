#!/usr/bin/env bash

set -Eeuo pipefail

export PROJECT_NAME=$1
export TMPDIR="$RUNNER_TEMP"
export REWRITE_IMAGE_NAME="build.local/dist/${PROJECT_NAME}"

echo "SYSTEM_COMMON_CACHE=${SYSTEM_COMMON_CACHE:=$HOME/cache}" >>"$GITHUB_ENV"

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=../common/functions-build-host.sh
source "./common/functions-build-host.sh"

if [[ ${CI+found} != found ]]; then
	die "This script is only for CI"
fi

sudo bash "./build.sh" || die "Build failed"
