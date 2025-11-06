#!/bin/bash

bluetooth_status=$(bluetoothctl show | grep "Powered" | awk '{print $2}')

if [ "$bluetooth_status" == "yes" ]; then
    echo '{"text": " On", "tooltip": "Bluetooth is On", "class": "bluetooth-on"}'
else
    echo '{"text": " Off", "tooltip": "Bluetooth is Off", "class": "bluetooth-off"}'
fi

case "$1" in
    "toggle")
        if [ "$bluetooth_status" == "yes" ]; then
            bluetoothctl power off
        else
            bluetoothctl power on
        fi
        ;;
esac