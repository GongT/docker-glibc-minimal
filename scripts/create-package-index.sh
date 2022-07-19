#!/usr/bin/env bash

mkdir -p packages

for PKG in "${PACKAGES[@]}"; do
	echo "create index of $PKG"

	dnf --quiet --forcearch x86_64 repoquery -l "$PKG.x86_64" "$PKG.noarch" \
		>"packages/$PKG.lst"

done
