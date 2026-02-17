#!/bin/bash

# Get current power state and echo true/false
if [[ $(bluetoothctl show | grep "Powered: yes") ]]; then
    echo true
else
    echo false
fi
