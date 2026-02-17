#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# This script sets up themes, icons, and fonts.
# It assumes the repository is cloned to ~/Hyprland-Arch-Config

REPO_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"
HOME_DIR="$HOME"

echo "Starting themes, icons, and fonts setup..."

# Create .icons and .themes directories if they don't exist
mkdir -p "$HOME_DIR/.icons" || { echo "Error: Failed to create $HOME_DIR/.icons directory."; exit 1; }
mkdir -p "$HOME_DIR/.themes" || { echo "Error: Failed to create $HOME_DIR/.themes directory."; exit 1; }
echo "Theme and icon directories ensured."

# Copy icons
DRACULA_ICONS_SOURCE="$REPO_DIR/themes-icons-fonts/icons/Dracula"
DRACULA_ICONS_DESTINATION="$HOME_DIR/.icons/Dracula"
if [ -d "$DRACULA_ICONS_SOURCE" ]; then
    echo "Copying Dracula icons from $DRACULA_ICONS_SOURCE to $DRACULA_ICONS_DESTINATION..."
    sudo cp -r "$DRACULA_ICONS_SOURCE" "$HOME_DIR/.icons/" || { echo "Error: Failed to copy Dracula icons."; exit 1; }
    echo "Dracula icons copied successfully."
else
    echo "Warning: Dracula icons source directory ($DRACULA_ICONS_SOURCE) not found. Skipping icon setup."
fi

# Copy themes
DRACULA_THEMES_SOURCE="$REPO_DIR/themes-icons-fonts/themes/Dracula"
DRACULA_THEMES_DESTINATION="$HOME_DIR/.themes/Dracula"
if [ -d "$DRACULA_THEMES_SOURCE" ]; then
    echo "Copying Dracula theme from $DRACULA_THEMES_SOURCE to $DRACULA_THEMES_DESTINATION..."
    sudo cp -r "$DRACULA_THEMES_SOURCE" "$HOME_DIR/.themes/" || { echo "Error: Failed to copy Dracula theme."; exit 1; }
    echo "Dracula theme copied successfully."
else
    echo "Warning: Dracula theme source directory ($DRACULA_THEMES_SOURCE) not found. Skipping theme setup."
fi

echo "Themes, icons, and fonts setup complete. You may need to configure your system to use them."