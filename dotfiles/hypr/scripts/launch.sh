#!/bin/bash

# Kill existing instances for reliable restart
killall -9 waybar
killall -9 swaync
killall -9 hypridle
killall -9 swww-daemon

# Autostart applications/services
swww-daemon &
/home/dhili/.config/hypr/start-waybar.sh &
hypridle &
dbus-update-activation-environment --systemd GTK_THEME=Dracula XDG_CURRENT_DESKTOP=Hyprland &
~/.config/hypr/scripts/capslock_daemon.sh &
~/.config/hypr/scripts/cliphist-init.sh &
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
bluetoothctl power off &
nmcli radio wifi off &
swaync &
nm-applet &
