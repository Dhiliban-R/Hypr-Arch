#!/bin/bash

# ------------------------------------------------------
# Installation Script for hyprland-arch-config
# ------------------------------------------------------

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# ------------------------------------------------------
# Install packages
# ------------------------------------------------------

echo "Installing packages from official repositories..."
sudo pacman -S --needed - < "$SCRIPT_DIR/packages/pacman_pkglist.txt"

echo "Installing packages from AUR..."
paru -S --needed - < "$SCRIPT_DIR/packages/paru_pkglist.txt"

# ------------------------------------------------------
# Create symbolic links
# ------------------------------------------------------

echo "Creating symbolic links for dotfiles..."

# Link files in the home directory
ln -sf "$SCRIPT_DIR/dotfiles/.bash_profile" "$HOME/.bash_profile"
ln -sf "$SCRIPT_DIR/dotfiles/.bashrc" "$HOME/.bashrc"
ln -sf "$SCRIPT_DIR/dotfiles/.gtkrc-2.0" "$HOME/.gtkrc-2.0"
ln -sf "$SCRIPT_DIR/dotfiles/.profile" "$HOME/.profile"
ln -sf "$SCRIPT_DIR/dotfiles/.zshrc" "$HOME/.zshrc"

# Link directories and files in .config
CONFIG_DIR="$HOME/.config"
DOTFILES_CONFIG_DIR="$SCRIPT_DIR/dotfiles/config"

# Create .config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Link all items in the dotfiles/config directory
for item in "$DOTFILES_CONFIG_DIR"/*; do
    item_name=$(basename "$item")
    ln -sf "$item" "$CONFIG_DIR/$item_name"
done

echo "Installation complete!"
echo "Please restart your shell for the changes to take effect."
