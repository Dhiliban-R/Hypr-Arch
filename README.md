# Hyprland Arch Linux Configuration: A Comprehensive Setup Guide

## 🚀 Overview

This repository provides a complete, step-by-step guide to installing Arch Linux from scratch and setting up a highly customized Hyprland Wayland desktop environment. It includes dotfiles, installation scripts, and theming instructions for a modern, cohesive workflow.

**Target Audience:** Arch Linux users comfortable with command-line operations, seeking a detailed and opinionated guide for a Hyprland desktop.

## ✨ Features

- **Full Arch Linux Installation:** Detailed guide for a UEFI-based Arch installation.
- **Hyprland:** Cutting-edge Wayland tiling compositor.
- **Waybar:** Dynamic and highly customizable status bar.
- **Wofi:** Efficient application launcher.
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

## 🖼️ Wallpaper & Theming

- **Wallpaper:** Managed by `hyprpaper`.
    - Configuration: `~/.config/hypr/hyprpaper.conf`
    - Preloaded wallpapers are stored in `~/Hyprland-Arch-Config/wallpapers/`.
    - Ensure `exec-once = hyprpaper` is present in `hyprland.conf`.
- **Theming:** GTK themes are handled by `nwg-look`. The configuration uses the **Dracula** theme.

## ⌨️ System-Wide Keybindings

This configuration uses a consistent and "smart" keybinding philosophy across the desktop environment.

**For a complete, automatically updated list of all configured keybindings, please refer to:**
👉 **[Keybindings.md](Keybindings.md)**

## 🔄 Synchronization

This repository is designed to be easily synchronized with your local system state.

### ⬆️ Pushing Local Changes to Repository
To update the repository with your current local configurations and package lists:
1.  **Copy Dotfiles:**
    ```bash
    cp -rf ~/.config/{hypr,waybar,wofi,mako,btop,fastfetch,Thunar,wezterm,wlogout,yazi} ~/Hyprland-Arch-Config/dotfiles/
    cp -f ~/.zshrc ~/Hyprland-Arch-Config/dotfiles/zshrc
    cp -f ~/.config/starship.toml ~/Hyprland-Arch-Config/dotfiles/starship.toml
    ```
2.  **Update Package Lists:**
    - `pacman -Qqen > ~/Hyprland-Arch-Config/packages/pacman_pkglist.txt`
    - `pacman -Qqem > ~/Hyprland-Arch-Config/packages/paru_pkglist.txt`
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
    exit
    ```
    Replace placeholders as needed.
- Test with:
    ```bash
    ping -c 3 archlinux.org
    ```

### 1.4 Update System Clock

```bash
timedatectl set-ntp true
```

### 1.5 Identify Your Disk

List devices and identify your target disk:

```bash
lsblk
```

> **Replace `/dev/sdX` in all commands below with your actual target disk (e.g., `/dev/sda`, `/dev/nvme0n1`).**

### 1.6 Wipe Existing Partitions

**WARNING: This will erase all data on the disk.**

```bash
sgdisk --zap-all /dev/sdX
```

### 1.7 Partition the Disk (`cfdisk`)

```bash
cfdisk /dev/sdX
```

1. Select `gpt`.
2. Create EFI System Partition (`512M`, type: `EFI System`).
3. Create Swap Partition (e.g., `4G` or `8G`, type: `Linux swap`).
4. Create Root Partition (remaining space, type: `Linux filesystem`).
5. Write changes and quit.
6. Verify with `lsblk`.

### 1.8 Format the Partitions

```bash
mkfs.fat -F32 /dev/sdX1    # EFI
mkswap /dev/sdX2           # Swap
mkfs.ext4 /dev/sdX3        # Root
swapon /dev/sdX2           # Activate swap
```

### 1.9 Mount the File Systems

```bash
mount /dev/sdX3 /mnt
mkdir -p /mnt/boot
mount /dev/sdX1 /mnt/boot
```

### 1.10 Install Essential Packages

```bash
pacstrap -K /mnt base linux linux-firmware vim git sudo networkmanager grub efibootmgr os-prober
```

### 1.11 Generate fstab

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

### 1.12 Chroot into the New System

```bash
arch-chroot /mnt
```

### 1.13 Configure Time Zone

```bash
ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
hwclock --systohc
```
Replace `Region/City` accordingly.

### 1.14 Localization

1. Edit `/etc/locale.gen`, uncomment needed locales (e.g., `en_US.UTF-8 UTF-8`).
2. Generate locales:
    ```bash
    locale-gen
    ```
3. Set default locale:
    ```bash
    echo LANG=en_US.UTF-8 > /etc/locale.conf
    ```

### 1.15 Set Hostname and Hosts File

```bash
echo myhostname > /etc/hostname  # Replace with your hostname
vim /etc/hosts
```
Add:
```
127.0.0.1    localhost
::1          localhost
127.0.1.1    myhostname.localdomain myhostname
```

### 1.16 Set Root Password

```bash
passwd
```

### 1.17 Create a New User

```bash
useradd -m -G wheel,audio,video,storage,input -s /bin/bash yourusername
passwd yourusername
```

### 1.18 Configure Sudoers

```bash
pacman -S sudo
EDITOR=vim visudo
```
Uncomment: `# %wheel ALL=(ALL:ALL) ALL`

### 1.19 Install Bootloader (GRUB)

```bash
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
```

### 1.20 Exit Chroot and Reboot

```bash
exit
umount -R /mnt
reboot
```
**Remove USB when prompted.**

---

## 💻 Part 2: Hyprland Desktop Environment Setup

After rebooting into your new Arch install, log in with your user account.

### 2.1 Initial Post-Install Setup

#### 2.1.1 Connect to the Internet

For Wi-Fi:
```bash
sudo systemctl enable --now NetworkManager
nmcli device wifi list
nmcli device wifi connect <YOUR_WIFI_SSID> password <YOUR_WIFI_PASSWORD>
```

#### 2.1.2 Install Git

```bash
sudo pacman -S git
```

#### 2.1.3 Install an AUR Helper (`paru`)

```bash
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd ..
rm -rf paru
```

#### 2.1.4 Clone this Repository

```bash
git clone https://github.com/Dhiliban-R/Hypr-Arch.git ~/Hyprland-Arch-Config
cd ~/Hyprland-Arch-Config
```

### 2.2 Run Installation Scripts

#### 2.2.1 Make Scripts Executable

```bash
chmod +x ./install/*.sh
```

#### 2.2.2 Install Packages

```bash
./install/install_packages.sh
```

#### 2.2.3 Setup Dotfiles

```bash
./install/setup_dotfiles.sh
```

#### 2.2.4 Setup Themes, Icons, and Fonts

```bash
./install/setup_themes_icons_fonts.sh
```

### 2.3 Enable Services

```bash
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager
```
For a display manager (`sddm`):
```bash
sudo systemctl enable sddm
```

### 2.4 Start Hyprland

- **From TTY:** Log in and run `Hyprland`
- **With Display Manager:** Reboot and select `Hyprland` session at login (install and enable `sddm` as above).

---

## ⚙️ Part 3: Post-Setup & Customization

### 3.1 Keybindings

The core configuration for Hyprland is located in `~/.config/hypr/hyprland.conf`.

**For a complete, automatically updated list of all configured keybindings, please refer to:**
👉 **[Keybindings.md](Keybindings.md)**

### 3.2 Customization Files

- **Hyprland:** `~/.config/hypr/hyprland.conf`
- **Waybar:** `~/.config/waybar/config`, `style.css`
- **Wofi:** `~/.config/wofi/config`, `style.css`
- **WezTerm:** `~/.config/wezterm/wezterm.lua`
- **Mako:** `~/.config/mako/config`
- **GTK Themes:**  
  - Install `lxappearance`: `sudo pacman -S lxappearance`
  - Set "Dracula" theme.

### 3.3 Wallpaper Configuration

Set wallpaper with `hyprpaper`. In `~/.config/hypr/hyprland.conf`:

```ini
exec-once = hyprpaper
wallpaper = DP-1,/path/to/your/wallpaper.jpg
```

---

## ⚠️ Part 4: Troubleshooting Common Issues

- **Hyprland Fails to Start / Black Screen:** Check `~/.local/share/hyprland/hyprland.log`.
- **Waybar / Wofi Not Themed Correctly:** Ensure Nerd Fonts are installed.
- **No Notifications:** Make sure `mako` is running.

---

## 📚 Further Resources

- [Hyprland Wiki](https://wiki.hyprland.org/)
- [Arch Wiki](https://wiki.archlinux.org/)
- [Waybar Wiki](https://github.com/Alexays/Waybar/wiki)
