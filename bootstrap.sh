#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# =============================================================================
# Hyprland Arch Linux Bootstrap Script
# =============================================================================
# This script automates the cloning of the Hypr-Arch repository and the
# execution of the main installation script. Run this on a fresh Arch Linux
# install with an active internet connection.
#
# Usage:
# curl -L https://raw.githubusercontent.com/Dhiliban-R/Hypr-Arch/main/bootstrap.sh -o bootstrap.sh
# chmod +x bootstrap.sh
# ./bootstrap.sh
# =============================================================================

REPO_URL="https://github.com/Dhiliban-R/Hypr-Arch.git"
REPO_DIR="$HOME/Hyprland-Arch-Config"

echo "================================================="
echo "Starting Hyprland Arch Linux Bootstrap"
echo "================================================="

# --- Check for internet connection ---
echo "--> Checking for internet connectivity..."
if ! ping -c 1 archlinux.org &> /dev/null; then
    echo "Error: No internet connection detected. Please connect to the internet and try again."
    exit 1
fi
echo "--> Internet connection confirmed."

# --- Install Git ---
echo "--> Checking for and installing git..."
if ! command -v git &> /dev/null; then
    sudo pacman -Syu --noconfirm --needed git || { echo "Error: Failed to install git."; exit 1; }
fi
echo "--> git is installed."

# --- Clone the repository ---
if [ ! -d "$REPO_DIR" ]; then
    echo "--> Cloning the Hypr-Arch repository to $REPO_DIR..."
    git clone "$REPO_URL" "$REPO_DIR" || { echo "Error: Failed to clone the repository."; exit 1; }
else
    echo "--> Repository already exists at $REPO_DIR. Skipping clone."
fi

# --- Execute the main installation script ---
MAIN_INSTALL_SCRIPT="$REPO_DIR/install/full_install_automated.sh"
if [ -f "$MAIN_INSTALL_SCRIPT" ]; then
    echo "--> Executing the main installation script..."
    chmod +x "$MAIN_INSTALL_SCRIPT"
    "$MAIN_INSTALL_SCRIPT"
else
    echo "Error: Main installation script not found at $MAIN_INSTALL_SCRIPT."
    exit 1
fi

echo "================================================="
echo "✅ Bootstrap process complete."
echo "The main installation script has finished."
echo "Please reboot your system."
echo "================================================="
