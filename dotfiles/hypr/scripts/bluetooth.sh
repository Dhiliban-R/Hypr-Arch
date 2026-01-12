#!/bin/bash

# Toggle Bluetooth and Open Manager

# Check if powered on
IS_ON=$(bluetoothctl show | grep "Powered: yes")

if [ -n "$IS_ON" ]; then
    # Turn Off
    bluetoothctl power off
    # OFF = Red
    /home/dhili/.local/bin/notify-system --type bluetooth --state off --text "OFF"
else
    # Turn On
    rfkill unblock bluetooth
    bluetoothctl power on
    
    # Open Blueman Manager
    GTK_THEME=Dracula GTK_ICON_THEME=Dracula blueman-manager &
    
    sleep 1.5
    
    # Check for connected devices
    DEVICES=$(bluetoothctl devices Connected | cut -d ' ' -f 3- | paste -sd ", " -)
    
    if [ -n "$DEVICES" ]; then
        # Connected = Green
        /home/dhili/.local/bin/notify-system --type bluetooth --state connected --text "On ($DEVICES)"
    else
        # Disconnected = Red
        /home/dhili/.local/bin/notify-system --type bluetooth --state disconnected --text "On (Disconnected)"
    fi
fi