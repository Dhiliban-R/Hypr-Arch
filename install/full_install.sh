#!/bin/bash

# This script orchestrates the full installation of Arch Linux with Hyprland
# based on the hyprland-arch-config repository.

# Exit immediately if a command exits with a non-zero status.
set -e

REPO_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"

echo "Starting full Hyprland Arch Linux setup..."

# Ensure scripts are executable
chmod +x "$REPO_DIR/install/install_packages.sh"
chmod +x "$REPO_DIR/install/setup_dotfiles.sh"
chmod +x "$REPO_DIR/install/setup_themes_icons_fonts.sh"

echo "Step 1: Installing packages..."
"$REPO_DIR/install/install_packages.sh"

echo "Step 2: Setting up dotfiles..."
"$REPO_DIR/install/setup_dotfiles.sh"

echo "Step 3: Setting up themes, icons, and fonts..."
"$REPO_DIR/install/setup_themes_icons_fonts.sh"

echo "Full Hyprland Arch Linux setup complete! Please reboot your system."
