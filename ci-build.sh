#!/usr/bin/env bash

set -Eeuo pipefail
export TMPDIR="$RUNNER_TEMP"

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/.."
# shellcheck source=../common/functions-build-host.sh
source "./common/functions-build-host.sh"


if [[ ${CI+found} != found ]]; then
	die "This script is only for CI"
fi

export -r PROJECT_NAME=$1

export REWRITE_IMAGE_NAME="build.local/dist/${PROJECT_NAME}"

sudo bash "./build.sh" || die "Build failed"
