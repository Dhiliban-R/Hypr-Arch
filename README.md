# Hyprland Arch Linux Configuration: A Comprehensive Setup Guide

## 🚀 Overview

This repository provides a complete, step-by-step guide to installing Arch Linux from scratch and setting up a highly customized Hyprland Wayland desktop environment. It includes dotfiles, installation scripts, and theming instructions for a modern, cohesive workflow.

**Target Audience:** Arch Linux users comfortable with command-line operations, seeking a detailed and opinionated guide for a Hyprland desktop.

## ✨ Features

- **Full Arch Linux Installation:** Detailed guide for a UEFI-based Arch installation.
- **Hyprland:** Cutting-edge Wayland tiling compositor.
- **Waybar:** Dynamic and highly customizable status bar.
- **Wofi:** Efficient application launcher.
- **Swaylock:** Secure screen locker.
- **Mako:** Lightweight notification daemon.
- **Wezterm:** Feature-rich, GPU-accelerated terminal emulator (configured with Lua).
- **Thunar:** Fast and user-friendly file manager.
- **Yazi:** Blazing fast terminal file manager written in Rust.
- **Btop:** Resource monitor that shows usage and stats for processor, memory, disks, network and processes.
- **Fastfetch:** Like neofetch, but much faster because written in C.
- **Starship:** The minimal, blazing-fast, and infinitely customizable prompt for any shell.
- **Smart Clipboard & Selection Logic:** Integrated experience between WezTerm and Zsh.
    - **Smart Copy:** Ctrl+Shift+C (copies mouse selection or Zsh active region).
    - **Smart Cut/Paste/Delete:** Ctrl+Shift+X/V/Backspace (integrated with Zsh ZLE widgets).
    - **Session Aware:** Automatically switches between `wl-copy` (Wayland) and `xclip` (X11).
- **Dracula Theme:** Cohesive dark theme applied across the desktop.
- **Essential Utilities:** Includes `grim` (screenshot), `slurp` (region selection), `wl-clipboard` (CRITICAL for clipboard management and Neovim/Wezterm integration), `hyprpaper` (wallpaper utility), `polkit-gnome` (authentication agent), `xdg-desktop-portal-hyprland`, and `xdg-desktop-portal-gtk` (screen sharing/compatibility).
- **Automated Setup:** Scripts for package installation and dotfile deployment.

## ⌨️ System-Wide Keybindings

This configuration uses a consistent and "smart" keybinding philosophy across the desktop environment.

### 🖥️ System & Session Control

| Key | Action |
| :--- | :--- |
| `SUPER + L` | **Lock Screen** (Swaylock) |
| `SUPER + X` | **Power Menu** (Logout, Suspend, Reboot, Shutdown) |
| `SUPER + SHIFT + R` | **Reload** Hyprland Configuration |
| `SUPER + SHIFT + N` | **Toggle WiFi** (On/Off) |
| `SUPER + SHIFT + B` | **Bluetooth Manager** (Blueman) |

### 🪟 Window Management (Hyprland)

| Key | Action |
| :--- | :--- |
| `SUPER + W` | **Close** Active Window |
| `SUPER + P` | **Toggle Split** Orientation (Vert/Horiz) |
| `SUPER + F` | Toggle **Floating** Mode |
| `SUPER + M` | Toggle **Fullscreen** |
| `SUPER + Arrows` | **Move Focus** (Left, Right, Up, Down) |
| `SUPER + 1-0` | Switch to **Workspace** 1-10 |
| `SUPER + SHIFT + 1-0` | **Move Window** to Workspace 1-10 |
| `SUPER + SHIFT + M` | Move Window to **Special Workspace** |
| `SUPER + Mouse Drag` | **Move** Window |
| `SUPER + Mouse Resize` | **Resize** Window |
| `Scroll Wheel` | Switch Workspace (on Desktop) |

### 🚀 Application Shortcuts

| Key | Action |
| :--- | :--- |
| `SUPER + SPACE` | **App Launcher** (Wofi) |
| `SUPER + Q` | **Terminal** (WezTerm) |
| `SUPER + E` | **File Manager** (Thunar) |
| `SUPER + V` | **Code Editor** (VS Code) |
| `SUPER + O` | **Office** (LibreOffice) |
| `SUPER + N` | **Notes** (Obsidian) |
| `SUPER + T` | **Telegram** |
| `SUPER + SHIFT + G` | **Gemini Assistant** (CLI) |
| `SUPER + SHIFT + Y` | **Yazi** (CLI File Manager) |
| `SUPER + SHIFT + T` | **OCR Tool** (Extract Text from Screen) |

### 🔊 Media & Hardware

| Key | Action |
| :--- | :--- |
| `F2 / F3` | **Brightness** Decrease / Increase |
| `F7 / F8` | **Volume** Decrease / Increase |
| `Mute Key` | **Mute** Audio |
| `Play/Pause Key` | Media Play / Pause |
| `Next/Prev Key` | Media Next / Previous |

### 📂 File Management (Yazi CLI)

| Key | Action |
| :--- | :--- |
| `Arrows / h,j,k,l` | **Navigate** Files/Directories |
| `Enter` | **Open** File / Enter Directory |
| `p` | Go to **Parent** Directory |
| `cc` | **Copy** Selected File(s) |
| `vv` | **Paste** File(s) |
| `dd` | **Delete** Selected File(s) |
| `r` | **Rename** File |
| `/` or `Ctrl + s` | **Search** |
| `q` | **Quit** |

### 📟 Terminal (WezTerm)

Context-aware bindings that handle both mouse selections and Zsh text regions.

| Key | Action |
| :--- | :--- |
| `Ctrl + Shift + C` | **Smart Copy:** Copies mouse selection if present, otherwise copies Zsh active region. |
| `Ctrl + Shift + X` | **Smart Cut:** Cuts text (integrated with Zsh). |
| `Ctrl + Shift + V` | **Universal Paste:** Pastes from clipboard (auto-clears selection first). |
| `Ctrl + Backspace` | Delete Word Backward |
| `Ctrl + Shift + Backspace` | Delete Selected Text |
| `Ctrl + Shift + Z` | Undo |
| `Ctrl + Shift + _` | Redo |
| `Ctrl + +/-/0` | Increase / Decrease / Reset Font Size |
| `Ctrl + T` | New Tab |
| `Ctrl + W` | Close Tab |
| `Alt + Arrows` | Navigate Panes |
| `Ctrl + \` | Split Horizontal |
| `Ctrl + Shift + \|` | Split Vertical |

### 🐚 Shell (Zsh)

GUI-like text navigation and editing.

| Key | Action |
| :--- | :--- |
| `Ctrl + Arrows` | Jump Words |
| `Shift + Arrows` | Select Character/Line |
| `Ctrl + Shift + Arrows` | Select Word (Continuous) |
| `Ctrl + A` | Select All |
| `Alt + S` | **Smart Sudo:** Toggles `sudo` at the start of the command. |
| `Shift + Enter` | Soft Newline |

### 🛠️ Utilities & Interactive Bars

| Feature | Interaction |
| :--- | :--- |
| **Screenshot** | `SUPER + S` (Select region -> Edit in Swappy) |
| **Waybar Workspaces** | Click to Switch Workspace |
| **Waybar Network** | Click WiFi Icon to Toggle Connection |
| **Power Menu** | Select from: Lock, Suspend, Reboot, Shutdown |

## 🔄 Synchronization

This repository is designed to be easily synchronized with your local system state.

### ⬆️ Pushing Local Changes to Repository
To update the repository with your current local configurations and package lists:
1.  **Copy Dotfiles:** `cp -r ~/.config/{hypr,waybar,wofi,mako,btop,fastfetch,swaylock,Thunar,wezterm,wlogout,yazi} ~/Hyprland-Arch-Config/dotfiles/` && `cp ~/.zshrc ~/Hyprland-Arch-Config/dotfiles/zshrc` && `cp ~/.config/starship.toml ~/Hyprland-Arch-Config/dotfiles/starship.toml`
2.  **Update Package Lists:**
    - `pacman -Qqe > ~/Hyprland-Arch-Config/packages/pacman_pkglist.txt`
    - `paru -Qme > ~/Hyprland-Arch-Config/packages/paru_pkglist.txt`
3.  **Commit and Push:** Use standard git commands to push changes to your remote repository.

### ⬇️ Pulling Changes to Local System
To apply updates from the repository to your system:
1.  **Pull Changes:** `git pull origin main`
2.  **Run Setup Script:** `./install/setup_dotfiles.sh` (This will create symlinks and backup existing files).

## 📋 Pre-Installation Requirements

Before you begin, ensure you have:

- **Arch Linux Installation Medium:** Download the latest Arch Linux ISO from [Arch Linux Downloads](https://archlinux.org/download/).
- **Bootable USB Creator:** A tool like Balena Etcher or Rufus to flash the ISO to a USB drive.
- **Stable Internet Connection:** Essential for the entire installation process.
- **Backup:** **CRITICAL:** Back up any important data before proceeding, as this guide involves partitioning and formatting your drive.

---

## 💾 Part 1: Arch Linux Base Installation

This section guides you through the fundamental Arch Linux installation. For more in-depth explanations, refer to the [official Arch Linux Installation Guide](https://wiki.archlinux.org/title/Installation_guide).

> **IMPORTANT:**  
> This guide assumes a UEFI system and an active internet connection. It also assumes you are installing on a single drive and will **remove all existing data on that drive**.

### 1.1 Boot into Live Environment

1. Insert the Arch Linux USB drive into your computer.
2. Enter your BIOS/UEFI settings (usually by pressing `Del`, `F2`, `F10`, or `F12` during startup).
3. Change the boot order to prioritize the USB drive, or select it from a boot menu.
4. Save changes and exit BIOS/UEFI. Boot from the USB drive.
5. Select `Arch Linux install medium (x86_64, UEFI)` from the boot menu and press Enter.
6. You will be greeted by the Arch Linux live environment (CLI).

### 1.2 Verify Boot Mode

Ensure you are in UEFI mode:

```bash
ls /sys/firmware/efi/efivars
```

- **If output is shown:** You are in UEFI mode. Proceed.
- **If no output or error:** Reboot and enable UEFI in BIOS/UEFI settings, disable Legacy/CSM.

### 1.3 Connect to the Internet

#### For Ethernet (Wired):

- Connection should work automatically. Test with:
    ```bash
    ping -c 3 archlinux.org
    ```
- **If no replies:** Check cable, try `dhcpcd`, or inspect with `ip a`.

#### For Wi-Fi:

- Use `iwctl`:
    ```bash
    sudo iwctl
    ```
    Then:
    ```bash
    device list
    station <your_wifi_device> scan
    station <your_wifi_device> get-networks
    station <your_wifi_device> connect <YOUR_WIFI_SSID>
    ```

---

## 🖼️ Wallpaper Setup

Wallpapers are managed by `hyprpaper`.

1.  **Location:** Place your wallpapers in `~/Hyprland-Arch-Config/wallpapers/` (or any directory you prefer).
2.  **Configuration:** Edit `~/.config/hypr/hyprpaper.conf` to point to your wallpaper image:

    ```conf
    preload = /home/username/Hyprland-Arch-Config/wallpapers/your_image.jpg
    wallpaper = ,/home/username/Hyprland-Arch-Config/wallpapers/your_image.jpg
    ```
    *(Replace `/home/username/` with your actual home directory path)*

---

## 🚀 Quick Setup for New Systems

To set up a new Arch Linux system with this configuration:

1.  **Perform Arch Linux Base Installation:** Follow "Part 1" and "Part 2" (up to "2.1.4 Clone this Repository").
2.  **Run the installation scripts:**
    ```bash
    cd ~/Hyprland-Arch-Config
    chmod +x ./install/*.sh
    ./install/install_packages.sh
    ./install/setup_dotfiles.sh
    ./install/setup_themes_icons_fonts.sh
    ```
3.  **Enable Services and start Hyprland:** Follow from "2.3 Enable Services" onwards.
- [Hyprland Wiki](https://wiki.hyprland.org/)
- [Arch Wiki](https://wiki.archlinux.org/)
- [Waybar Wiki](https://github.com/Alexays/Waybar/wiki)