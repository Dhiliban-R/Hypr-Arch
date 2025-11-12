#!/bin/bash

# Function to check if a command exists
command_exists () {
    command -v "$1" >/dev/null 2>&1
}

echo "Starting application installation..."

# Install paru if not present
if ! command_exists paru; then
    echo "paru not found. Installing paru..."
    sudo pacman -S --noconfirm base-devel git
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    (cd /tmp/paru && makepkg -si --noconfirm)
    rm -rf /tmp/paru
else
    echo "paru is already installed."
fi

# Install npm if not present
if ! command_exists npm; then
    echo "npm not found. Installing npm..."
    sudo pacman -S --noconfirm npm
else
    echo "npm is already installed."
fi

echo "Updating system packages..."
paru -Syu --noconfirm

echo "Installing core applications..."
paru -S --noconfirm \
    hyprland \
    yazi \
    waybar \
    
    btop \
    telegram-desktop \
    neovim \
    timeshift \
    vlc \
    libreoffice-still \
    blueman \
    networkmanager \
    hyprpaper \
    wezterm \
    brave-browser \
    visual-studio-code-bin \
    obsidian

echo "Installing gemini-cli via npm..."
npm install -g gemini-cli

echo "Application installation complete."

