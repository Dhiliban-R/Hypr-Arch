#!/bin/bash

# Function to check if a command exists
command_exists () {
    command -v "$1" >/dev/null 2>&1
}

echo "Starting application installation..."

# Install yay if not present
if ! command_exists yay; then
    echo "yay not found. Installing yay..."
    sudo pacman -S --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
    rm -rf /tmp/yay
else
    echo "yay is already installed."
fi

# Install npm if not present
if ! command_exists npm; then
    echo "npm not found. Installing npm..."
    sudo pacman -S --noconfirm npm
else
    echo "npm is already installed."
fi

echo "Updating system packages..."
yay -Syu --noconfirm

echo "Installing core applications..."
yay -S --noconfirm \
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

