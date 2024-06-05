#!/usr/bin/env bash

set -Eeuo pipefail

if [[ ${DIST_FOLDER+found} != found ]]; then
	declare -r DIST_FOLDER="/mnt/dist"
fi
if [[ ${SOURCE_FOLDER+found} != found ]]; then
	declare -r SOURCE_FOLDER="/mnt/source"
fi
declare -r FILELIST="/tmp/FILELIST.txt"

echo "Query $# packages: $*"

for I; do
	rpm --root "$SOURCE_FOLDER" -ql "$I"
done \
	| grep -v --fixed-strings -- '/.build-id' \
	| grep -v --fixed-strings -- '/usr/share/doc' \
	| grep -v --fixed-strings -- '/usr/share/man' \
	| grep -v --fixed-strings -- '/var/cache' \
	| grep -v --fixed-strings -- '/var/log' \
	| grep -v --fixed-strings -- '/run' \
	| sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
	| sed 's#^/##g' \
	| sed -E 's#^(bin|sbin|lib|lib64)#usr/\1#g' \
	| sort | uniq \
	>"$FILELIST"

echo "Creating tarball..."
cd "$SOURCE_FOLDER"
# xargs ls -d >/dev/null <"$FILELIST"
tar --create \
	--no-recursion \
	--ignore-failed-read \
	--ignore-command-error \
	--sparse \
	--no-seek \
	"--directory=$SOURCE_FOLDER" \
	"--files-from=$FILELIST" \
	>/tmp/result.tar.gz

ls -lh /tmp/result.tar.gz
FILES_IN_ZIP=$(tar tf /tmp/result.tar.gz | wc -l)
echo " -- $(wc -l "$FILELIST" | awk '{print $1}') files wanted"
echo " -- $FILES_IN_ZIP files included"

if [[ $FILES_IN_ZIP -lt 100 ]]; then
	echo "file count seems wrong." >&2
	exit 1
fi

echo "Creating dist..."
cd "$DIST_FOLDER"

for LIB in lib lib64 bin sbin; do
	mkdir -p ./usr/$LIB
	ln -s ./usr/$LIB $LIB
done
tar -xf /tmp/result.tar.gz

if [[ -e "usr/sbin/busybox" ]]; then
	BUSYBOX="/usr/sbin/busybox"
elif [[ -e "usr/sbin/busybox.shared" ]]; then
	BUSYBOX="/usr/sbin/busybox.shared"
else
	BUSYBOX=
fi

if [[ "$BUSYBOX" ]]; then
	echo "Preparing busybox..."
	mkdir usr/xbin
	chroot . "$BUSYBOX" --install -s /usr/xbin

	if ! [[ -e usr/bin/sh ]]; then
		ln -s "$BUSYBOX" usr/bin/sh
	fi
fi

if [[ -e usr/bin/bash ]]; then
	echo "Preparing shell (BASH)..."
	rm -f usr/xbin/sh usr/bin/sh
	ln -s ./bash usr/bin/sh
fi

echo "Install complete..."
mkdir data
