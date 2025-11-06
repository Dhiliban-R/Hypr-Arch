#!/bin/bash

# Install pacman packages
echo "Installing pacman packages..."
sudo pacman -Syu --needed - < ../packages/pacman_pkglist.txt

# Install yay (AUR helper) if not already installed
if ! command -v yay &> /dev/null; then
    echo "yay not found. Installing yay..."
    sudo pacman -S --needed git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si)
    rm -rf /tmp/yay
fi

# Install AUR packages
if [ -f ../packages/yay_pkglist.txt ]; then
    echo "Installing AUR packages..."
    yay -S --needed - < <(grep -v "yay-git" ../packages/yay_pkglist.txt)
else
    echo "AUR package list (yay_pkglist.txt) not found. Skipping AUR package installation."
fi

echo "Package installation complete."
