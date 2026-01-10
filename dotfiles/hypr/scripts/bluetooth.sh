#!/bin/bash

# Toggle Bluetooth and Open Manager

# Check if powered on
IS_ON=$(bluetoothctl show | grep "Powered: yes")

if [ -n "$IS_ON" ]; then
    # Turn Off
    bluetoothctl power off
    # OFF = Red
    notify-send -c style_red -u low -i bluetooth-disabled "Bluetooth" "OFF"
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
        notify-send -c style_green -u low -i bluetooth-active "Bluetooth" "On ($DEVICES)"
    else
        # Disconnected = Red
        notify-send -c style_red -u low -i bluetooth-active "Bluetooth" "On (Disconnected)"
    fi
fi