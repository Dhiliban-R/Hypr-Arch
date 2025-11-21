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
- **Wezterm:** Feature-rich, GPU-accelerated terminal emulator.
- **Thunar:** Fast and user-friendly file manager.
- **Dracula Theme:** Cohesive dark theme applied across the desktop.
- **Essential Utilities:** Includes `grim` (screenshot), `slurp` (region selection), `wl-clipboard` (clipboard management), `polkit-gnome` (authentication agent), `xdg-desktop-portal-hyprland`, and `xdg-desktop-portal-gtk` (screen sharing/compatibility).
- **Automated Setup:** Scripts for package installation and dotfile deployment.

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
git clone https://github.com/Dhiliban-R/Hypr-Arch ~/Hypr-Arch
cd ~/Hypr-Arch
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

The main config file is `~/.config/hypr/hyprland.conf`. Example keybindings:

| Keybinding          | Action                                    |
|---------------------|-------------------------------------------|
| Super + Q           | Open Wezterm (Terminal)                   |
| Super + W           | Close active window                       |
| Super + Space       | Open Wofi (Launcher)                      |
| Super + X           | Powermenu                                 |
| Super + G           | Gemini-CLI                                |
| Super + E           | Thunar                                    |
| Super + Y           | Yazi                                      |
| Super + B           | Open Brave                                |
| Super + T           | Open Telegram                             |
| Super + V           | Open VS Code (if installed)               |
| Super + O           | Open LibreOffice (if installed)           |
| Super + N           | Open Obsidian (if installed)              |
| Super + M           | Toggle Maximize window                    |
| Super + F           | Toggle Floating window                    |
| Super + Shift + Q   | Exit Hyprland Session                     |
| Super + Shift + R   | Reload Hyprland Session                   |
| Super + Shift + B   | Blueman-manager                           |
| Super + Shift + N   | Network manager                           |
| Super + S           | Screenshot (select region with `slurp`)   |
| Super + L           | Lock Screen with Swaylock                 |
| Super + 1-9         | Switch to Workspace 1-9                   |
| Super + Shift + 1-9 | Move window to Workspace 1-9              |
| Super + Left/Right  | Move focus to adjacent window             |

Customize as needed in `hyprland.conf`.

### 3.2 Customization Files

- **Hyprland:** `~/.config/hypr/hyprland.conf`
- **Waybar:** `~/.config/waybar/config`, `style.css`
- **Wofi:** `~/.config/wofi/config`, `style.css`
- **Wezterm:** `~/.config/wezterm/wezterm.lua`
- **Mako:** `~/.config/mako/config`
- **Yazi:** `~/.config/yazi/config.toml`
- **Thunar:** `~/.config/Thunar/`
- **GTK Themes:**  
  The `setup_themes_icons_fonts.sh` script copies the Dracula theme and icon files to `~/.themes/Dracula` and `~/.icons/Dracula` respectively.
  - Install `lxappearance`: `sudo pacman -S lxappearance`
  - Set "Dracula" theme.
  - Or edit:
    ```ini
    [Settings]
    gtk-theme-name=Dracula
    gtk-icon-theme-name=Dracula
    gtk-cursor-theme-name=Dracula
    ```
    in `~/.config/gtk-3.0/settings.ini` and `~/.config/gtk-4.0/settings.ini`.

### 3.3 Wallpaper Configuration

Wallpapers can be managed by `hyprpaper` using a configuration file, typically `~/.config/hypr/hyprpaper.conf`. This repository includes a `wallpapers/` directory where you can place your desired images.

To use `hyprpaper`:
1.  Ensure `hyprpaper` is configured to run in your `~/.config/hypr/hyprland.conf` (e.g., `exec-once = hyprpaper`).
2.  Create or edit `~/.config/hypr/hyprpaper.conf` to specify your wallpapers.

Example `~/.config/hypr/hyprpaper.conf` entry:
```ini
preload = ~/Hyprland-Arch-Config/wallpapers/your_wallpaper.jpg
wallpaper = DP-1,~/Hyprland-Arch-Config/wallpapers/your_wallpaper.jpg
# For multiple monitors:
# wallpaper = HDMI-A-1,~/Hyprland-Arch-Config/wallpapers/another_wallpaper.png
```
Find your monitor names with `hyprctl monitors`.

### 3.4 Display Manager Integration (Optional)

If you use `sddm`, ensure it's enabled and Hyprland session file exists at `/usr/share/wayland-sessions/hyprland.desktop`.

---

## ⚠️ Part 4: Troubleshooting Common Issues

- **Hyprland Fails to Start / Black Screen:**
  - Check `~/.local/share/hyprland/hyprland.log`
  - Ensure correct graphics drivers are installed.
  - Verify `xdg-desktop-portal-hyprland` is running.
  - Ensure `XDG_SESSION_TYPE=wayland` and `XDG_CURRENT_DESKTOP=Hyprland` are set.

- **Waybar / Wofi Not Themed Correctly:**
  - Ensure Nerd Fonts or icon fonts are installed.
  - Verify GTK theme via `lxappearance` or `settings.ini`.

- **No Notifications:**
  - Make sure `mako` is running (set in `exec-once`).

- **Applications Not Launching:**
  - Confirm the application is installed.
  - Check your `PATH`.

- **Screen Tearing / Performance Issues:**
  - Consult Hyprland Wiki for GPU optimizations.
  - Enable `vsync` in `hyprland.conf`.

---

## 📚 Further Resources

- [Hyprland Wiki](https://wiki.hyprland.org/)
- [Arch Wiki](https://wiki.archlinux.org/)
- [Waybar Wiki](https://github.com/Alexays/Waybar/wiki)

---

## 🚀 Quick Setup for New Systems

To set up a new Arch Linux system with this configuration:

1.  **Perform Arch Linux Base Installation:** Follow "Part 1: Arch Linux Base Installation" and "Part 2: Hyprland Desktop Environment Setup" (up to "2.1.4 Clone this Repository") in this `README.md`.
2.  **Run the full installation script:** This script automates the installation of all necessary packages (both pacman and AUR), sets up dotfiles, and configures themes, icons, and fonts.
    ```bash
    cd ~/Hypr-Arch # Assuming you cloned to ~/Hypr-Arch
    ./install/full_install.sh
    ```
3.  **Continue Hyprland Setup:** Continue with "Part 2: Hyprland Desktop Environment Setup" from "2.3 Enable Services" onwards.
