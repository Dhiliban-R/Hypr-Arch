#!/bin/bash

# This script sets up themes, icons, and fonts.
# It assumes the repository is cloned to ~/hyprland-arch-config

REPO_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"

echo "Setting up themes, icons, and fonts..."

# Create .icons and .themes directories if they don't exist
mkdir -p ~/.icons
mkdir -p ~/.themes

# Copy icons
if [ -d "$REPO_DIR/themes-icons-fonts/icons/Dracula" ]; then
    cp -r "$REPO_DIR/themes-icons-fonts/icons/Dracula" ~/.icons/
    echo "Dracula icons copied."
fi

# Copy themes
if [ -d "$REPO_DIR/themes-icons-fonts/themes/Dracula" ]; then
    cp -r "$REPO_DIR/themes-icons-fonts/themes/Dracula" ~/.themes/
    echo "Dracula theme copied."
fi

echo "Themes, icons, and fonts setup complete. You may need to configure your system to use them."
