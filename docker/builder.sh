#!/usr/bin/env bash

set -Eeuo pipefail

cat > /etc/dnf/dnf.conf <<- 'CFG'
	[main]
	gpgcheck=1
	installonly_limit=3
	clean_requirements_on_remove=True
	keepcache=True
	exit_on_lock=True
	cachedir=/var/cache/dnf
	ip_resolve=4
	max_parallel_downloads=10
CFG

echo "Generating file index..."
echo "" > /tmp/related-files

NATIVE_PKGS=(glibc glibc-common libgcc setup "$@")

PKGS_TO_SHOW=()
for I in "${NATIVE_PKGS[@]}"; do
	PKGS_TO_SHOW+=("$I.x86_64" "$I.noarch")
done

dnf --forcearch x86_64 repoquery -l "${PKGS_TO_SHOW[@]}" \
	| grep -v --fixed-strings -- '/.build-id' \
	| grep -v --fixed-strings -- '/usr/share/doc' \
	| grep -v --fixed-strings -- '/usr/share/man' \
		>> /tmp/related-files

sed -i 's#^/##g' /tmp/related-files

echo "Installing packages..."
dnf install --installroot=/tmp/install --releasever=/ --setopt=cachedir=../../../../../../../../../../../../../../../var/cache/dnf \
	-y "${NATIVE_PKGS[@]}"

echo "Creating tarball..."
tar --create \
	--no-recursion \
	--ignore-failed-read \
	--ignore-command-error \
	--sparse \
	--no-seek \
	--remove-files \
	--directory=/tmp/install \
	--files-from /tmp/related-files \
	--file=/tmp/result.tar.gz || true

ls -lh /tmp/result.tar.gz
echo " -- $(wc -l /tmp/related-files) files wanted"
echo " -- $(tar tf /tmp/result.tar.gz | wc -l) files included"

echo "Creating dist..."
mkdir /tmp/dist
cd /tmp/dist
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
	ln -s /usr/sbin/busybox /usr/bin/sh
fi

if [[ -e usr/bin/bash ]]; then
	echo "Preparing shell (BASH)..."
	rm -f usr/xbin/sh /usr/bin/sh
	ln -s /usr/bin/bash /usr/bin/sh
fi

echo "Install complete..."
mkdir data
