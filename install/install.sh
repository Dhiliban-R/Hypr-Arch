#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# =============================================================================
# Hyprland Arch Linux Installation Script
# =============================================================================
# This script orchestrates the full installation of the Hyprland desktop
# environment, including packages, dotfiles, and theming.
# =============================================================================

REPO_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"
HOME_DIR="$HOME"

# --- Function Definitions ----------------------------------------------------

# Log a message
log() {
    echo "--> $1"
}

# Log an error and exit
error() {
    echo "Error: $1" >&2
    exit 1
}

# Check for internet connection
check_internet() {
    log "Checking for internet connectivity..."
    if ! ping -c 1 archlinux.org &> /dev/null; then
        error "No internet connection detected. Please connect to the internet and try again."
    fi
    log "Internet connection confirmed."
}

# Install packages
install_packages() {
    log "Starting package installation..."
    PACKAGES_DIR="$REPO_DIR/packages"

    # Install pacman packages
    if [ -f "$PACKAGES_DIR/pacman_pkglist.txt" ]; then
        log "Installing pacman packages..."
        sudo pacman -Syu --needed --noconfirm - < "$PACKAGES_DIR/pacman_pkglist.txt" || error "Failed to install pacman packages."
    else
        log "Warning: pacman_pkglist.txt not found. Skipping pacman packages."
    fi

    # Check for AUR helper
    AUR_HELPER=""
    if command -v paru &> /dev/null; then
        AUR_HELPER="paru"
    elif command -v yay &> /dev/null; then
        AUR_HELPER="yay"
    fi

    # Install AUR helper if not found
    if [ -z "$AUR_HELPER" ]; then
        log "No AUR helper (paru or yay) found. Attempting to install paru..."
        sudo pacman -S --needed --noconfirm git base-devel || error "Failed to install git and base-devel for paru."
        (
            git clone https://aur.archlinux.org/paru.git /tmp/paru &&
            cd /tmp/paru &&
            makepkg -si --noconfirm &&
            cd / &&
            rm -rf /tmp/paru
        ) || error "Failed to build and install paru."
        AUR_HELPER="paru"
    fi
    log "Using $AUR_HELPER as AUR helper."

    # Install AUR packages
    if [ -f "$PACKAGES_DIR/paru_pkglist.txt" ]; then
        log "Installing AUR packages..."
        # Add nerd-fonts to the list
        echo "nerd-fonts" >> "$PACKAGES_DIR/paru_pkglist.txt"
        $AUR_HELPER -S --needed --noconfirm - < "$PACKAGES_DIR/paru_pkglist.txt" || error "Failed to install AUR packages."
    else
        log "Warning: paru_pkglist.txt not found. Skipping AUR packages."
    fi

    log "Package installation completed."
}

# Setup dotfiles
setup_dotfiles() {
    log "Starting dotfiles setup..."
    DOTFILES_DIR="$REPO_DIR/dotfiles"

    # Ensure .config and .local/bin directories exist
    mkdir -p "$HOME_DIR/.config"
    mkdir -p "$HOME_DIR/.local/bin"

    # Find all files and directories in the dotfiles directory
    for item in $(find "$DOTFILES_DIR" -mindepth 1 -maxdepth 1 -printf "%P\n"); do
        source_path="$DOTFILES_DIR/$item"
        target_path="$HOME_DIR/$(basename "$item")"

        # Special handling for dotfiles that need to be in .config
        if [[ "$item" == "waybar" || "$item" == "wofi" || "$item" == "btop" || "$item" == "wlogout" || "$item" == "Thunar" || "$item" == "wezterm" || "$item" == "yazi" || "$item" == "gtk-3.0" || "$item" == "hypr" || "$item" == "fastfetch" || "$item" == "swaync" || "$item" == "user-dirs.dirs" || "$item" == "brave-flags.conf" ]]; then
            target_path="$HOME_DIR/.config/$(basename "$item")"
        elif [[ "$item" == ".zshrc" || "$item" == ".gtkrc-2.0" ]]; then
            target_path="$HOME_DIR/$(basename "$item")"
        elif [[ "$item" == "bin" ]]; then
            target_path="$HOME_DIR/.local/bin"
        fi

        # Backup existing files
        if [ -e "$target_path" ] || [ -L "$target_path" ]; then
            timestamp=$(date +%Y%m%d_%H%M%S)
            backup_path="${target_path}.bak_${timestamp}"
            log "Backing up $target_path to $backup_path"
            mv "$target_path" "$backup_path"
        fi

        # Symlink or copy
        if [[ "$item" == "hypr" || "$item" == "fastfetch" || "$item" == "swaync" ]]; then
            log "Copying and processing $item -> $target_path"
            cp -r "$source_path" "$target_path"
            find "$target_path" -type f -exec sed -i "s|{{USER_HOME}}|$HOME_DIR|g" {} +
            find "$target_path" -type f -exec sed -i "s|{{REPO_DIR}}|$REPO_DIR|g" {} +
        else
            log "Linking $item -> $target_path"
            ln -sf "$source_path" "$target_path"
        fi
    done

    log "Dotfiles setup complete."
}

# Setup themes and icons
setup_themes_icons() {
    log "Starting themes and icons setup..."
    THEMES_DIR="$REPO_DIR/themes-icons-fonts"

    # Create .icons and .themes directories
    mkdir -p "$HOME_DIR/.icons"
    mkdir -p "$HOME_DIR/.themes"

    # Copy icons
    if [ -d "$THEMES_DIR/icons" ]; then
        log "Copying icons..."
        cp -r "$THEMES_DIR/icons/"* "$HOME_DIR/.icons/" || error "Failed to copy icons."
    fi

    # Copy themes
    if [ -d "$THEMES_DIR/themes" ]; then
        log "Copying themes..."
        cp -r "$THEMES_DIR/themes/"* "$HOME_DIR/.themes/" || error "Failed to copy themes."
    fi

    log "Themes and icons setup complete."
}

# Post-installation checks
post_install_checks() {
    log "Starting post-installation checks..."

    # Check for Nerd Fonts
    if ! fc-list | grep -i "nerd font" &> /dev/null; then
        log "Warning: Nerd Fonts not found. UI may not render correctly."
    else
        log "Nerd Fonts detected."
    fi

    # Check for wl-clipboard
    if ! command -v wl-copy &> /dev/null; then
        log "Warning: 'wl-clipboard' is not installed. Clipboard integration will be limited."
    else
        log "wl-clipboard detected."
    fi

    log "Post-installation checks complete."
}

# --- Main Execution ----------------------------------------------------------

main() {
    echo "================================================="
    echo "Starting Hyprland Arch Linux Setup"
    echo "================================================="

    check_internet
    install_packages
    setup_dotfiles
    setup_themes_icons
    post_install_checks

    echo "================================================="
    echo "✅ Hyprland Arch Linux setup complete!"
    echo "Please reboot your system for all changes to take effect."
    echo "================================================="
}

main "$@"
