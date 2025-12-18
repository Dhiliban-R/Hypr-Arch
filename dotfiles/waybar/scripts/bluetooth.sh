#!/bin/bash

# Function to get Bluetooth status
get_bluetooth_status() {
    if bluetoothctl show | grep -q "Powered: yes"; then
        if bluetoothctl info | grep -q "Connected: yes"; then
            echo "" # Connected
        else
            echo "" # On but not connected
        fi
    else
        echo "" # Off
    fi
}

# Function to toggle Bluetooth
toggle_bluetooth() {
    if bluetoothctl show | grep -q "Powered: yes"; then
        bluetoothctl power off
    else
        rfkill unblock bluetooth
        bluetoothctl power on
    fi
    pkill -SIGRTMIN+10 waybar
}

# Main logic
case "$1" in
    toggle)
        toggle_bluetooth
        ;;
    *)
        get_bluetooth_status
        ;;
esac