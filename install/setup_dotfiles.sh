#!/bin/bash

# This script sets up symlinks for dotfiles.
# It assumes the repository is cloned to ~/hyprland-arch-config

REPO_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"

echo "Setting up dotfiles..."

# Create .config directory if it doesn't exist
mkdir -p ~/.config

# Symlink config directories
ln -sf "$REPO_DIR/dotfiles/hypr" ~/.config/hypr
ln -sf "$REPO_DIR/dotfiles/waybar" ~/.config/waybar
ln -sf "$REPO_DIR/dotfiles/wofi" ~/.config/wofi
ln -sf "$REPO_DIR/dotfiles/mako" ~/.config/mako
ln -sf "$REPO_DIR/dotfiles/btop" ~/.config/btop
ln -sf "$REPO_DIR/dotfiles/fastfetch" ~/.config/fastfetch
ln -sf "$REPO_DIR/dotfiles/swaylock" ~/.config/swaylock
ln -sf "$REPO_DIR/dotfiles/Thunar" ~/.config/Thunar
ln -sf "$REPO_DIR/dotfiles/wezterm" ~/.config/wezterm
ln -sf "$REPO_DIR/dotfiles/wlogout" ~/.config/wlogout
ln -sf "$REPO_DIR/dotfiles/yazi" ~/.config/yazi

# Symlink config files
ln -sf "$REPO_DIR/dotfiles/starship.toml" ~/.config/starship.toml
ln -sf "$REPO_DIR/dotfiles/hypr/hyprpaper.conf" ~/.config/hypr/hyprpaper.conf

echo "Dotfiles setup complete. You may need to log out and back in for some changes to take effect."
