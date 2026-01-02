#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

REPO_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"
PACKAGES_DIR="$REPO_DIR/packages"

echo "Starting package installation..."

# Install pacman packages
echo "Installing pacman packages from $PACKAGES_DIR/pacman_pkglist.txt..."
sudo pacman -Syu --needed - < "$PACKAGES_DIR/pacman_pkglist.txt" || { echo "Error: Failed to install pacman packages."; exit 1; }
echo "Pacman packages installed successfully."

# Install paru (AUR helper) if not already installed
if ! command -v paru &> /dev/null; then
    echo "paru not found. Attempting to install paru..."
    sudo pacman -S --needed git base-devel || { echo "Error: Failed to install git and base-devel for paru."; exit 1; }
    git clone https://aur.archlinux.org/paru.git /tmp/paru || { echo "Error: Failed to clone paru repository."; exit 1; }
    (cd /tmp/paru && makepkg -si --noconfirm) || { echo "Error: Failed to build and install paru."; exit 1; }
    rm -rf /tmp/paru
    echo "paru installed successfully."
else
    echo "paru is already installed."
fi

# Install AUR packages
if [ -f "$PACKAGES_DIR/paru_pkglist.txt" ]; then
    echo "Installing AUR packages from $PACKAGES_DIR/paru_pkglist.txt..."
    # Filter out paru-git if it's in the list, as paru itself is handled above
    paru -S --needed --noconfirm - < <(grep -v "paru-git" "$PACKAGES_DIR/paru_pkglist.txt") || { echo "Error: Failed to install AUR packages."; exit 1; }
    echo "AUR packages installed successfully."
else
    echo "AUR package list ($PACKAGES_DIR/paru_pkglist.txt) not found. Skipping AUR package installation."
fi

echo "All package installation steps completed."