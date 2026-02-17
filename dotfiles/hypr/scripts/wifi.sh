#!/bin/bash

# Toggle Wifi
state=$(nmcli radio wifi)

if [ "$state" == "enabled" ]; then
    nmcli radio wifi off
    # OFF = Red
    /home/dhili/.local/bin/notify-system --type wifi --state off --text "OFF"
else
    # Turn ON
    nmcli radio wifi on
    
    # Immediate feedback (Green border as it is active/searching)
    /home/dhili/.local/bin/notify-system --type wifi --state searching --text "Searching..."
    
    # Wait for connection (Faster checks: 0.5s x 10 tries = 5 seconds max)
    for i in {1..10}; do
        sleep 0.5
        connection=$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d: -f2)
        if [ -n "$connection" ]; then
            # Connected = Green
            /home/dhili/.local/bin/notify-system --type wifi --state connected --text "On ($connection)"
            pkill -SIGRTMIN+9 waybar # Refresh waybar
            exit 0
        fi
    done
    
    # If no connection after 5 seconds:
    # Disconnected = Red
    /home/dhili/.local/bin/notify-system --type wifi --state disconnected --text "On (Disconnected)"
fi

pkill -SIGRTMIN+9 waybar # Refresh waybar
