#!/bin/bash

# Get current power state
current_state=$(bluetoothctl show | grep "Powered: yes")

if [[ -n "$current_state" ]]; then
    # Bluetooth is on, turn it off
    bluetoothctl power off
else
    # Bluetooth is off, turn it on
    bluetoothctl power on
fi
