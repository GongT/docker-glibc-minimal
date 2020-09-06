#!/usr/bin/env bash

set -Eeuo pipefail

declare -r DIST_FOLDER="/mnt/dist"
declare -r SOURCE_FOLDER="/mnt/source"

echo "Query $# packages: $*"

PKGS_TO_SHOW=()
for I; do
	PKGS_TO_SHOW+=("$I.x86_64" "$I.noarch")
done

dnf --forcearch x86_64 repoquery -l "${PKGS_TO_SHOW[@]}" \
	| grep -v --fixed-strings -- '/.build-id' \
	| grep -v --fixed-strings -- '/usr/share/doc' \
	| grep -v --fixed-strings -- '/usr/share/man' \
	| sed 's#^/##g' \
		> "$DIST_FOLDER/FILELIST"

echo "Creating tarball..."
tar --create \
	--no-recursion \
	--ignore-failed-read \
	--ignore-command-error \
	--sparse \
	--no-seek \
	"--directory=$SOURCE_FOLDER" \
	"--files-from=$DIST_FOLDER/FILELIST" \
	--file=/tmp/result.tar.gz || true

ls -lh /tmp/result.tar.gz
FILES_IN_ZIP=$(tar tf /tmp/result.tar.gz | wc -l)
echo " -- $(wc -l "$DIST_FOLDER/FILELIST") files wanted"
echo " -- $FILES_IN_ZIP files included"

if [[ $FILES_IN_ZIP -lt 100 ]]; then
	echo "file count seems wrong." >&2
	exit 1
fi

echo "Creating dist..."
cd "$DIST_FOLDER"
tar -xf /tmp/result.tar.gz

for LIB in lib lib64 bin sbin; do
	if [[ -d $LIB ]]; then
		mv $LIB/* usr/$LIB
		rmdir $LIB
	fi
	ln -s /usr/$LIB $LIB
done

if [[ -e usr/sbin/busybox ]]; then
	echo "Preparing busybox..."
	mkdir usr/xbin
	chroot . /usr/sbin/busybox --install -s /usr/xbin

	if ! [[ -e usr/bin/sh ]]; then
		ln -s /usr/sbin/busybox usr/bin/sh
	fi
fi

if [[ -e usr/bin/bash ]]; then
	echo "Preparing shell (BASH)..."
	rm -f usr/xbin/sh usr/bin/sh
	ln -s /usr/bin/bash usr/bin/sh
fi

echo "Install complete..."
mkdir data
