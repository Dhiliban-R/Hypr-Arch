#!/bin/bash

# Function to get Wi-Fi status
get_wifi_status() {
    if nmcli radio wifi | grep -q "enabled"; then
        WIFI_SSID=$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes:' | head -n 1 | sed 's/^yes://')

        if [ -n "$WIFI_SSID" ]; then
            echo "󰤨 $WIFI_SSID"
        else
            echo "󰤨 On"
        fi
    else
        echo "󰤮 Off"
    fi
}

# Function to toggle Wi-Fi
toggle_wifi() {
    if nmcli radio wifi | grep -q "enabled"; then
        nmcli radio wifi off
    else
        rfkill unblock wifi
        nmcli radio wifi on
    fi
    pkill -SIGRTMIN+9 waybar
}

# Main logic
case "$1" in
    toggle)
        toggle_wifi
        ;;
    *)
        get_wifi_status
        ;;
esac
