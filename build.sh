#!/usr/bin/env bash

declare -rx TAG="$1"

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ./common/functions-build.sh

MAXIMUM_PACKAGES=(tzdata busybox-shared ncurses-base ncurses-libs bash)
declare -x BASE_PKGS=(glibc glibc-common libgcc setup)

PPATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
PSHELL=""
case "$TAG" in
bash)
	PKGS=(tzdata busybox-shared ncurses-base ncurses-libs bash)
	PSHELL="/usr/bin/bash"
	;;
busybox)
	PKGS=(tzdata busybox-shared)
	PSHELL="/usr/bin/sh"
	;;
latest)
	PKGS=()
	;;
*)
	die "Unknown tag: $TAG"
	;;
esac

(
	MAXIMUM_PACKAGES_STR=" ${MAXIMUM_PACKAGES[*]} "
	for I in "${PKGS[@]}"; do
		if [[ $MAXIMUM_PACKAGES_STR != *" $I "* ]]; then
			die "Package $I not inside MAXIMUM_PACKAGES"
		fi
	done
)

if [[ " ${PKGS[*]} " == *"busybox"* ]]; then
	PPATH+=":/usr/xbin"
fi

## prepare them
STEP="安装依赖"
TFILE=$(create_temp_file dependencies-list)
for i in "${BASE_PKGS[@]}" "${MAXIMUM_PACKAGES[@]}"; do
	echo "$i" >>"$TFILE"
done
# POST_SCRIPT=$(<scripts/create-package-index.sh)
make_base_image_by_dnf "my-glibc-build" "$TFILE"
# unset POST_SCRIPT

## create result
STEP="收集文件"
STORAGE_IMG=$BUILDAH_LAST_IMAGE
do_hash() {
	{
		echo "$STORAGE_IMG"
		cat "scripts/builder.collect.sh"
		declare -f "do_build"
	} | md5sum
}
do_build() {
	local RESULT=$1 RESULT_MNT STORAGE STORAGE_MNT OPERATOR
	RESULT_MNT=$(buildah mount "$RESULT")

	STORAGE=$(create_if_not "$id-temp-store" "$STORAGE_IMG")
	STORAGE_MNT=$(buildah mount "$STORAGE")

	OPERATOR=$(create_if_not "fedora_copy_glibc" "fedora:latest")

	echo "${PKGS[@]}" "${BASE_PKGS[@]}"
	buildah run $(use_fedora_dnf_cache) "$(mount_tmpfs /tmp)" \
		"--volume=$RESULT_MNT:/mnt/dist" \
		"--volume=$STORAGE_MNT:/mnt/source:ro" \
		"$OPERATOR" \
		bash -s - "${PKGS[@]}" "${BASE_PKGS[@]}" <"scripts/builder.collect.sh"

	buildah umount "$STORAGE"
	buildah rm "$STORAGE"
}

id="glibc-built-$TAG"
buildah_cache_start scratch
buildah_cache2 "$id" do_hash do_build

info_log ""

STEP="更新配置"
buildah_config "glibc-$TAG-final" \
	"--cmd=$PSHELL" "--env=PATH=$PPATH" \
	"--author=GongT <admin@gongt.me>" "--created-by=magic" \
	"--label=name=gongt/glibc:$TAG"
info_log ""

BASE_ANNO_ID="me.gongt.glibc.buildid"
DIST="docker.io/gongt/glibc:$TAG"
if image_exists "$DIST"; then
	LAST_FROM_ID=$(builah_get_annotation "$DIST" "$BASE_ANNO_ID")
	if [[ $LAST_FROM_ID == "$BUILDAH_LAST_IMAGE" ]]; then
		info_success "镜像没有任何修改"
		control_ci "set-env" "LAST_COMMITED_IMAGE" "$BUILDAH_LAST_IMAGE"
		exit
	else
		info_note "应用新镜像:\n  exists: ${LAST_FROM_ID}\n  create: ${BUILDAH_LAST_IMAGE}"
	fi
else
	info_note "不存在缓存镜像"
fi

RESULT=$(new_container "gongt-glibc-$TAG" "$BUILDAH_LAST_IMAGE")
xbuildah config --add-history \
	"--annotation=$BASE_ANNO_ID=$BUILDAH_LAST_IMAGE" \
	"$RESULT" >/dev/null
buildah commit --squash "$RESULT" "$DIST"
info "Done!"
