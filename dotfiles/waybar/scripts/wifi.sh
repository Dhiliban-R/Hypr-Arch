#!/bin/bash

# Function to get Wi-Fi status
get_wifi_status() {
    if nmcli radio wifi | grep -q "enabled"; then
        ACTIVE_CONNECTION_INFO=$(nmcli -t -f NAME,TYPE connection show --active)
        WIFI_SSID=$(echo "$ACTIVE_CONNECTION_INFO" | grep ':802-11-wireless$' | head -n 1 | cut -d':' -f1)

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
