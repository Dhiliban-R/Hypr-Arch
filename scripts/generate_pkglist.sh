#!/bin/bash

# This script generates/updates pacman_pkglist.txt and paru_pkglist.txt
# based on currently installed packages.

REPO_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"
PACKAGES_DIR="$REPO_DIR/packages"

echo "Generating pacman_pkglist.txt..."
pacman -Qqe > "$PACKAGES_DIR/pacman_pkglist.txt"

echo "Generating paru_pkglist.txt..."
if command -v paru &> /dev/null; then
    paru -Qqe > "$PACKAGES_DIR/paru_pkglist.txt"
else
    echo "Warning: paru not found. Skipping AUR package list generation."
    echo "" > "$PACKAGES_DIR/paru_pkglist.txt" # Ensure file exists, even if empty
fi

echo "Package lists generated successfully."
