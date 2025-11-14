#!/bin/bash

# This script sets up symlinks for dotfiles.
# It assumes the repository is cloned to ~/hyprland-arch-config

REPO_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"

echo "Setting up dotfiles..."

# Create .config directory if it doesn't exist
mkdir -p ~/.config

# Symlink top-level dotfiles
ln -sf "$REPO_DIR/dotfiles/.bashrc" ~/.bashrc
ln -sf "$REPO_DIR/dotfiles/.zshrc" ~/.zshrc
ln -sf "$REPO_DIR/dotfiles/.bash_profile" ~/.bash_profile
ln -sf "$REPO_DIR/dotfiles/.profile" ~/.profile
ln -sf "$REPO_DIR/dotfiles/.gtkrc-2.0" ~/.gtkrc-2.0

# Symlink config directories
ln -sf "$REPO_DIR/dotfiles/config/hypr" ~/.config/hypr
ln -sf "$REPO_DIR/dotfiles/config/waybar" ~/.config/waybar
ln -sf "$REPO_DIR/dotfiles/config/wofi" ~/.config/wofi
ln -sf "$REPO_DIR/dotfiles/config/mako" ~/.config/mako
ln -sf "$REPO_DIR/dotfiles/config/btop" ~/.config/btop
ln -sf "$REPO_DIR/dotfiles/config/Code" ~/.config/Code
ln -sf "$REPO_DIR/dotfiles/config/fastfetch" ~/.config/fastfetch
ln -sf "$REPO_DIR/dotfiles/config/gtk-3.0" ~/.config/gtk-3.0
ln -sf "$REPO_DIR/dotfiles/config/libreoffice" ~/.config/libreoffice
ln -sf "$REPO_DIR/dotfiles/config/obsidian" ~/.config/obsidian
ln -sf "$REPO_DIR/dotfiles/config/pulse" ~/.config/pulse

ln -sf "$REPO_DIR/dotfiles/config/swaylock" ~/.config/swaylock
ln -sf "$REPO_DIR/dotfiles/config/Thunar" ~/.config/Thunar
ln -sf "$REPO_DIR/dotfiles/config/wezterm" ~/.config/wezterm
ln -sf "$REPO_DIR/dotfiles/config/wlogout" ~/.config/wlogout

# Symlink config files
ln -sf "$REPO_DIR/dotfiles/config/starship.toml" ~/.config/starship.toml
ln -sf "$REPO_DIR/dotfiles/config/mimeapps.list" ~/.config/mimeapps.list
ln -sf "$REPO_DIR/dotfiles/config/kwalletrc" ~/.config/kwalletrc

echo "Dotfiles setup complete. You may need to log out and back in for some changes to take effect."
