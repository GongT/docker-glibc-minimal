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

NATIVE_PKGS=(glibc glibc-common libgcc setup "$@")
