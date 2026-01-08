#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# This script sets up symlinks for dotfiles.
# It assumes the repository is cloned to ~/Hyprland-Arch-Config

REPO_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"
HOME_DIR="$HOME"

echo "Starting dotfiles setup..."

# Create .config directory if it doesn't exist
mkdir -p "$HOME_DIR/.config" || { echo "Error: Failed to create $HOME_DIR/.config directory."; exit 1; }
echo "$HOME_DIR/.config directory ensured."

# Define dotfiles to symlink (directories and files)
# Key: name within dotfiles/ directory
# Value: target path relative to $HOME_DIR
declare -A dotfiles_to_symlink=(
    ["hypr"]=".config/hypr"
    ["waybar"]=".config/waybar"
    ["wofi"]=".config/wofi"
    ["mako"]=".config/mako"
    ["btop"]=".config/btop"
    ["fastfetch"]=".config/fastfetch"
    ["swaylock"]=".config/swaylock"
    ["Thunar"]=".config/Thunar"
    ["wezterm"]=".config/wezterm"
    ["wlogout"]=".config/wlogout"
    ["yazi"]=".config/yazi"
    ["starship.toml"]=".config/starship.toml"
    ["zshrc"]=".zshrc"
    [".bashrc"]=".bashrc"
    [".profile"]=".profile"
    [".bash_profile"]=".bash_profile"
)

# Loop through the dotfiles and create symlinks
for name in "${!dotfiles_to_symlink[@]}"; do
    source_path="$REPO_DIR/dotfiles/$name"
    target_path="$HOME_DIR/${dotfiles_to_symlink[$name]}"

    # Ensure parent directory exists for the target
    mkdir -p "$(dirname "$target_path")"

    if [ -e "$source_path" ]; then
        echo "Processing $name..."

        # Check if target exists
        if [ -e "$target_path" ] || [ -L "$target_path" ]; then
            # If it's already a correct symlink, skip
            if [ -L "$target_path" ] && [ "$(readlink -f "$target_path")" == "$source_path" ]; then
                echo "  Already linked correctly."
                continue
            fi

            # Backup existing file/dir
            timestamp=$(date +%Y%m%d_%H%M%S)
            backup_path="${target_path}.bak_${timestamp}"
            echo "  Backing up existing $target_path to $backup_path"
            mv "$target_path" "$backup_path"
        fi

        echo "  Symlinking $source_path to $target_path"
        ln -sf "$source_path" "$target_path"
    else
        echo "Warning: Source dotfile/directory not found: $source_path (Skipping)"
    fi
done

echo "Dotfiles setup complete. You may need to log out and back in for some changes to take effect."