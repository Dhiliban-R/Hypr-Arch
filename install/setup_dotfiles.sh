#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# =============================================================================
# Dotfiles Setup Script
# =============================================================================
# Links configuration files from the local repository to the system.
# Assumes the repository is cloned to ~/Hyprland-Arch-Config
# =============================================================================

REPO_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"
HOME_DIR="$HOME"

echo ">> Starting dotfiles synchronization..."

# Ensure .config directory exists
mkdir -p "$HOME_DIR/.config"

# Define dotfiles to symlink
# Key: Source name (in dotfiles/ dir) | Value: Target path (relative to HOME)
declare -A dotfiles_to_symlink=(
    ["waybar"]=".config/waybar"
    ["wofi"]=".config/wofi"
    ["mako"]=".config/mako"
    ["btop"]=".config/btop"
    ["Thunar"]=".config/Thunar"
    ["wezterm"]=".config/wezterm"
    ["wlogout"]=".config/wlogout"
    ["yazi"]=".config/yazi"
    ["starship.toml"]=".config/starship.toml"
    ["zshrc"]=".zshrc"
    ["bin"]=".local/bin"
    ["gtk-3.0"]=".config/gtk-3.0"
    ["gtk-2.0"]=".config/gtk-2.0"
    ["user-dirs.dirs"]=".config/user-dirs.dirs"
    ["brave-flags.conf"]=".config/brave-flags.conf"
)

# Define dotfiles to copy and process placeholders (for files that don't support ~ or $HOME)
declare -A dotfiles_to_copy=(
    ["hypr"]=".config/hypr"
    ["gtkrc-2.0"]=".gtkrc-2.0"
    ["fastfetch"]=".config/fastfetch"
)

# Execute Symlinking
for name in "${!dotfiles_to_symlink[@]}"; do
    source_path="$REPO_DIR/dotfiles/$name"
    target_path="$HOME_DIR/${dotfiles_to_symlink[$name]}"

    # Create parent dir if missing
    mkdir -p "$(dirname "$target_path")"

    if [ -e "$source_path" ]; then
        # Check if valid link already exists
        if [ -L "$target_path" ] && [ "$(readlink -f "$target_path")" == "$source_path" ]; then
            echo " [OK] $name is already linked."
            continue
        fi

        # Backup existing file/dir
        if [ -e "$target_path" ] || [ -L "$target_path" ]; then
            timestamp=$(date +%Y%m%d_%H%M%S)
            backup_path="${target_path}.bak_${timestamp}"
            echo " [BACKUP] Moving $target_path to $backup_path"
            mv "$target_path" "$backup_path"
        fi

        echo " [LINK] Linking $name -> $target_path"
        ln -sf "$source_path" "$target_path"
    else
        echo " [MISSING] Source $name not found in repo. Skipping."
    fi
done

# Execute Copying and Placeholder Replacement
for name in "${!dotfiles_to_copy[@]}"; do
    source_path="$REPO_DIR/dotfiles/$name"
    target_path="$HOME_DIR/${dotfiles_to_copy[$name]}"

    # Create parent dir if missing
    mkdir -p "$(dirname "$target_path")"

    if [ -e "$source_path" ]; then
        # Backup existing file/dir
        if [ -e "$target_path" ] || [ -L "$target_path" ]; then
            timestamp=$(date +%Y%m%d_%H%M%S)
            backup_path="${target_path}.bak_${timestamp}"
            echo " [BACKUP] Moving $target_path to $backup_path"
            mv "$target_path" "$backup_path"
        fi

        echo " [COPY] Copying and processing $name -> $target_path"
        cp -r "$source_path" "$target_path"
        
        # Replace placeholders with actual values
        if [ -d "$target_path" ]; then
            find "$target_path" -type f -exec sed -i "s|{{USER_HOME}}|$HOME_DIR|g" {} +
            find "$target_path" -type f -exec sed -i "s|{{REPO_DIR}}|$REPO_DIR|g" {} +
        else
            sed -i "s|{{USER_HOME}}|$HOME_DIR|g" "$target_path"
            sed -i "s|{{REPO_DIR}}|$REPO_DIR|g" "$target_path"
        fi
    else
        echo " [MISSING] Source $name not found in repo. Skipping."
    fi
done

echo ">> Dotfiles setup complete."

# Post-Install Checks
if ! command -v wl-copy &> /dev/null; then
    echo " [WARN] 'wl-clipboard' is not installed. Clipboard integration will be limited."
fi