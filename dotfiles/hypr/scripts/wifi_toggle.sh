#!/bin/bash

# Get current power state
current_state=$(nmcli radio wifi)

if [[ "$current_state" == "enabled" ]]; then
    # WiFi is enabled, turn it off
    nmcli radio wifi off
else
    # WiFi is disabled, turn it on
    nmcli radio wifi on
fi
