#!/usr/bin/env bash

declare -rx TAG="$1"

set -Eeuo pipefail

cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
source ./common/functions-build.sh

MAXIMUM_PACKAGES=(tzdata busybox ncurses-base ncurses-libs bash)
declare -x BASE_PKGS=(glibc glibc-common libgcc setup)

PPATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
PSHELL=""
case "$TAG" in
bash)
	PKGS=(tzdata busybox ncurses-base ncurses-libs bash)
	PSHELL="/usr/bin/bash"
	;;
busybox)
	PKGS=(tzdata busybox)
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
TFILE=$(create_temp_file dependencies-list)
for i in "${BASE_PKGS[@]}" "${MAXIMUM_PACKAGES[@]}"; do
	echo "$i" >>"$TFILE"
done
make_base_image_by_dnf "my-glibc-build" "$TFILE"

## create result
STORAGE_IMG=$BUILDAH_LAST_IMAGE
do_hash() {
	{
		echo "$STORAGE_IMG"
		cat "scripts/builder.collect.sh"
		cat "build.sh"
	} | md5sum
}
do_build() {
	local RESULT=$1 RESULT_MNT STORAGE STORAGE_MNT OPERATOR
	RESULT_MNT=$(buildah mount "$RESULT")

	STORAGE=$(create_if_not "$id-temp-store" "$STORAGE_IMG")
	STORAGE_MNT=$(buildah mount "$STORAGE")

	OPERATOR=$(create_if_not "fedora_copy_glibc" "fedora:latest")

	buildah run $(use_fedora_dnf_cache) "$(mount_tmpfs /tmp)" \
		"--volume=$RESULT_MNT:/mnt/dist" \
		"--volume=$STORAGE_MNT:/mnt/source:ro" \
		"$OPERATOR" \
		bash -s - "${PKGS[@]}" "${BASE_PKGS[@]}" <"scripts/builder.collect.sh"

	buildah umount "$STORAGE"
	buildah rm "$STORAGE"
}

id="glibc-built-$TAG"
buildah_cache_start "$id" scratch
buildah_cache2 "$id" do_hash do_build

info_log ""

RESULT=$(new_container "glibc-$TAG-final" "$BUILDAH_LAST_IMAGE")
buildah config \
	"--cmd=$PSHELL" "--env=PATH=$PPATH" \
	"--author=GongT <admin@gongt.me>" "--created-by=magic" \
	"--label=name=gongt/glibc:$TAG" "$RESULT"
info_log ""

buildah commit --squash "$RESULT" "docker.io/gongt/glibc:$TAG"
info "Done!"
