#!/bin/bash

# Fixed ID for updates
NOTIFY_ID=9998

# Toggle Wifi
state=$(nmcli radio wifi)

if [ "$state" == "enabled" ]; then
    nmcli radio wifi off
    # OFF = Red
    notify-send -r $NOTIFY_ID -c style_red -u low -i network-wireless-disconnected "Wi-Fi" "OFF"
else
    # Turn ON
    nmcli radio wifi on
    
    # Immediate feedback (Green border as it is active/searching)
    notify-send -r $NOTIFY_ID -c style_green -u low -i network-wireless-connected "Wi-Fi" "Searching..."
    
    # Wait for connection (Faster checks: 0.5s x 10 tries = 5 seconds max)
    for i in {1..10}; do
        sleep 0.5
        connection=$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d: -f2)
        if [ -n "$connection" ]; then
            # Connected = Green
            notify-send -r $NOTIFY_ID -c style_green -u low -i network-wireless-connected "Wi-Fi" "On ($connection)"
            exit 0
        fi
    done
    
    # If no connection after 5 seconds:
    # Disconnected = Red
    notify-send -r $NOTIFY_ID -c style_red -u low -i network-wireless-connected "Wi-Fi" "On (Disconnected)"
fi
