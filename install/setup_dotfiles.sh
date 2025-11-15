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
)

# Loop through and create symlinks
for source_name in "${!dotfiles_to_symlink[@]}"; do
    target_relative_path="${dotfiles_to_symlink[$source_name]}"
    source_path="$REPO_DIR/dotfiles/$source_name"
    destination_path="$HOME_DIR/$target_relative_path"

    # Ensure parent directory exists for the symlink
    mkdir -p "$(dirname "$destination_path")" || { echo "Error: Failed to create parent directory for $destination_path."; exit 1; }

    # Remove existing file/symlink at destination if it exists
    if [ -e "$destination_path" ] || [ -L "$destination_path" ]; then
        echo "Removing existing $destination_path..."
        rm -rf "$destination_path" || { echo "Error: Failed to remove existing $destination_path."; exit 1; }
    fi

    if [ -e "$source_path" ]; then
        echo "Creating symlink: $source_path -> $destination_path"
        ln -sf "$source_path" "$destination_path" || { echo "Error: Failed to create symlink for $source_name."; exit 1; }
    else
        echo "Warning: Source path $source_path not found. Skipping symlink for $source_name."
    fi
done

# Special case for hyprpaper.conf as its destination is nested within .config/hypr
HYPRPAPER_SOURCE="$REPO_DIR/dotfiles/hypr/hyprpaper.conf"
HYPRPAPER_DESTINATION="$HOME_DIR/.config/hypr/hyprpaper.conf"

if [ -f "$HYPRPAPER_SOURCE" ]; then
    mkdir -p "$(dirname "$HYPRPAPER_DESTINATION")" || { echo "Error: Failed to create parent directory for $HYPRPAPER_DESTINATION."; exit 1; }
    if [ -e "$HYPRPAPER_DESTINATION" ] || [ -L "$HYPRPAPER_DESTINATION" ]; then
        echo "Removing existing $HYPRPAPER_DESTINATION..."
        rm -rf "$HYPRPAPER_DESTINATION" || { echo "Error: Failed to remove existing $HYPRPAPER_DESTINATION."; exit 1; }
    fi
    echo "Creating symlink: $HYPRPAPER_SOURCE -> $HYPRPAPER_DESTINATION"
    ln -sf "$HYPRPAPER_SOURCE" "$HYPRPAPER_DESTINATION" || { echo "Error: Failed to create symlink for hyprpaper.conf."; exit 1; }
else
    echo "Warning: $HYPRPAPER_SOURCE not found. Skipping symlink for hyprpaper.conf."
fi

echo "Dotfiles setup complete. You may need to log out and back in for some changes to take effect."