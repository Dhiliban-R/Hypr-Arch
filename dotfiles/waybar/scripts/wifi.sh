#!/bin/bash

# Function to get Wi-Fi status
get_wifi_status() {
    if nmcli radio wifi | grep -q "enabled"; then
        # Get ACTIVE, RATE, and SSID.
        # Format: yes:RATE:SSID
        WIFI_INFO=$(nmcli -t -f ACTIVE,RATE,SSID dev wifi | grep '^yes:' | head -n 1)

        if [ -n "$WIFI_INFO" ]; then
            RATE=$(echo "$WIFI_INFO" | cut -d':' -f2)
            SSID=$(echo "$WIFI_INFO" | cut -d':' -f3-)

            # Measure latency (ping 8.8.8.8 with 1s timeout)
            PING=$(ping -c 1 -W 1 8.8.8.8 2>/dev/null)
            
            if [ $? -eq 0 ]; then
                # Extract time in ms (integer part)
                LATENCY=$(echo "$PING" | grep -o 'time=[0-9.]*' | cut -d= -f2 | cut -d. -f1)
                echo "󰤨 $SSID 󰓅 $RATE 󰄉 ${LATENCY}ms"
            else
                echo "󰤨 $SSID 󰓅 $RATE"
            fi
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
    # Refresh waybar
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