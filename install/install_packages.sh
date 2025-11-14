#!/bin/bash

# Install pacman packages
echo "Installing pacman packages..."
sudo pacman -Syu --needed - < /home/dhili/Hyprland-Arch-Config/packages/pacman_pkglist.txt

# Install paru (AUR helper) if not already installed
if ! command -v paru &> /dev/null; then
    echo "paru not found. Installing paru..."
    sudo pacman -S --needed git base-devel
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    (cd /tmp/paru && makepkg -si)
    rm -rf /tmp/paru
fi

# Install AUR packages
if [ -f /home/dhili/Hyprland-Arch-Config/packages/paru_pkglist.txt ]; then
    echo "Installing AUR packages..."
    paru -S --needed - < <(grep -v "paru-git" /home/dhili/Hyprland-Arch-Config/packages/paru_pkglist.txt)
else
    echo "AUR package list (paru_pkglist.txt) not found. Skipping AUR package installation."
fi

echo "Package installation complete."
