#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# =============================================================================
# Hyprland Arch Linux Full Automated Installation Script
# =============================================================================
# This script orchestrates the full installation of the Hyprland desktop
# environment, including packages, dotfiles, and theming.
# It is designed to be run from the root of the repository.
# =============================================================================

REPO_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"
HOME_DIR="$HOME"

echo "================================================="
echo "Starting Full Hyprland Arch Linux Setup"
echo "================================================="
echo "Repository directory: $REPO_DIR"
echo "Home directory: $HOME_DIR"
echo "================================================="

# -----------------------------------------------------------------------------
# STEP 1: PACKAGE INSTALLATION
# -----------------------------------------------------------------------------
echo ">> STEP 1: Installing all necessary packages..."

PACKAGES_DIR="$REPO_DIR/packages"

# Install pacman packages
if [ -f "$PACKAGES_DIR/pacman_pkglist.txt" ]; then
    echo "--> Installing pacman packages from $PACKAGES_DIR/pacman_pkglist.txt..."
    sudo pacman -Syu --needed - < "$PACKAGES_DIR/pacman_pkglist.txt" || { echo "Error: Failed to install pacman packages."; exit 1; }
    echo "--> Pacman packages installed successfully."
else
    echo "--> Warning: pacman_pkglist.txt not found. Skipping pacman packages."
fi

# Install paru (AUR helper) if not already installed
if ! command -v paru &> /dev/null; then
    echo "--> paru not found. Attempting to install paru..."
    sudo pacman -S --needed --noconfirm git base-devel || { echo "Error: Failed to install git and base-devel for paru."; exit 1; }
    (
      git clone https://aur.archlinux.org/paru.git /tmp/paru && 
      cd /tmp/paru && 
      makepkg -si --noconfirm && 
      cd / && 
      rm -rf /tmp/paru
    ) || { echo "Error: Failed to build and install paru."; exit 1; }
    echo "--> paru installed successfully."
else
    echo "--> paru is already installed."
fi

# Install AUR packages
if [ -f "$PACKAGES_DIR/paru_pkglist.txt" ]; then
    echo "--> Installing AUR packages from $PACKAGES_DIR/paru_pkglist.txt..."
    # Filter out paru-git if it's in the list, as paru itself is handled above
    paru -S --needed --noconfirm - < <(grep -v "paru-git" "$PACKAGES_DIR/paru_pkglist.txt") || { echo "Error: Failed to install AUR packages."; exit 1; }
    echo "--> AUR packages installed successfully."
else
    echo "--> Warning: paru_pkglist.txt not found. Skipping AUR packages."
fi

echo ">> Package installation completed."
echo "================================================="

# -----------------------------------------------------------------------------
# STEP 2: DOTFILES SETUP
# -----------------------------------------------------------------------------
echo ">> STEP 2: Setting up dotfiles..."

# Ensure .config and .local/bin directories exist
mkdir -p "$HOME_DIR/.config"
mkdir -p "$HOME_DIR/.local/bin"

# Define dotfiles to symlink
declare -A dotfiles_to_symlink=(
    ["waybar"]=".config/waybar"
    ["wofi"]=".config/wofi"
    ["btop"]=".config/btop"
    ["wlogout"]=".config/wlogout"
    ["Thunar"]=".config/Thunar"
    ["wezterm"]=".config/wezterm"
    ["yazi"]=".config/yazi"
    [".zshrc"]=".zshrc"
    ["gtk-3.0"]=".config/gtk-3.0"
    ["gtkrc-2.0"]=".gtkrc-2.0"
    ["user-dirs.dirs"]=".config/user-dirs.dirs"
    ["brave-flags.conf"]=".config/brave-flags.conf"
)

# Define dotfiles to copy and process placeholders
declare -A dotfiles_to_copy=(
    ["hypr"]=".config/hypr"
    ["fastfetch"]=".config/fastfetch"
    ["swaync"]=".config/swaync"
)

# Execute Symlinking
for name in "${!dotfiles_to_symlink[@]}"; do
    source_path="$REPO_DIR/dotfiles/$name"
    target_path="$HOME_DIR/${dotfiles_to_symlink[$name]}"

    mkdir -p "$(dirname "$target_path")"

    if [ -e "$source_path" ]; then
        if [ -L "$target_path" ] && [ "$(readlink -f "$target_path")" == "$source_path" ]; then
            echo "--> [OK] $name is already linked."
        else
            if [ -e "$target_path" ] || [ -L "$target_path" ]; then
                timestamp=$(date +%Y%m%d_%H%M%S)
                backup_path="${target_path}.bak_${timestamp}"
                echo "--> [BACKUP] Moving $target_path to $backup_path"
                mv "$target_path" "$backup_path"
            fi
            echo "--> [LINK] Linking $name -> $target_path"
            ln -sf "$source_path" "$target_path"
        fi
    else
        echo "--> [MISSING] Source $name not found in repo. Skipping."
    fi
done

# Execute Copying and Placeholder Replacement
for name in "${!dotfiles_to_copy[@]}"; do
    source_path="$REPO_DIR/dotfiles/$name"
    target_path="$HOME_DIR/${dotfiles_to_copy[$name]}"

    mkdir -p "$(dirname "$target_path")"

    if [ -e "$source_path" ]; then
        if [ -e "$target_path" ]; then
             timestamp=$(date +%Y%m%d_%H%M%S)
             backup_path="${target_path}.bak_${timestamp}"
             echo "--> [BACKUP] Moving $target_path to $backup_path"
             mv "$target_path" "$backup_path"
        fi
        echo "--> [COPY] Copying and processing $name -> $target_path"
        cp -r "$source_path" "$target_path"
        
        if [ -d "$target_path" ]; then
            find "$target_path" -type f -exec sed -i "s|{{USER_HOME}}|$HOME_DIR|g" {} +
            find "$target_path" -type f -exec sed -i "s|{{REPO_DIR}}|$REPO_DIR|g" {} +
        else
            sed -i "s|{{USER_HOME}}|$HOME_DIR|g" "$target_path"
            sed -i "s|{{REPO_DIR}}|$REPO_DIR|g" "$target_path"
        fi
    else
        echo "--> [MISSING] Source $name not found in repo. Skipping."
    fi
done

echo ">> Dotfiles setup complete."
echo "================================================="

# -----------------------------------------------------------------------------
# STEP 3: THEMES, ICONS, AND FONTS SETUP
# -----------------------------------------------------------------------------
echo ">> STEP 3: Setting up themes, icons, and fonts..."

# Create .icons and .themes directories
mkdir -p "$HOME_DIR/.icons"
mkdir -p "$HOME_DIR/.themes"

# Copy icons
DRACULA_ICONS_SOURCE="$REPO_DIR/themes-icons-fonts/icons/Dracula"
if [ -d "$DRACULA_ICONS_SOURCE" ]; then
    echo "--> Copying Dracula icons..."
    cp -r "$DRACULA_ICONS_SOURCE" "$HOME_DIR/.icons/" || { echo "Error: Failed to copy Dracula icons."; exit 1; }
    echo "--> Dracula icons copied successfully."
else
    echo "--> Warning: Dracula icons source directory not found. Skipping."
fi

# Copy themes
DRACULA_THEMES_SOURCE="$REPO_DIR/themes-icons-fonts/themes/Dracula"
if [ -d "$DRACULA_THEMES_SOURCE" ]; then
    echo "--> Copying Dracula theme..."
    cp -r "$DRACULA_THEMES_SOURCE" "$HOME_DIR/.themes/" || { echo "Error: Failed to copy Dracula theme."; exit 1; }
    echo "--> Dracula theme copied successfully."
else
    echo "--> Warning: Dracula theme source directory not found. Skipping."
fi

echo ">> Themes, icons, and fonts setup complete."
echo "================================================="

echo "✅ Full Hyprland Arch Linux setup complete!"
echo "Please reboot your system for all changes to take effect."
