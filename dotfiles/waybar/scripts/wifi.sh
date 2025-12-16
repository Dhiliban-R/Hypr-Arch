#!/bin/bash

# Function to get Wi-Fi status
get_wifi_status() {
    if nmcli radio wifi | grep -q "enabled"; then
        ESSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2)
        if [ -n "$ESSID" ]; then
            echo "󰤨 $ESSID"
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
        nmcli radio wifi on
    fi
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
