#!/bin/bash

if [ "$1" == "toggle" ]; then
    if nmcli radio wifi | grep -q "enabled"; then
        nmcli radio wifi off
    else
        nmcli radio wifi on
    fi
else
    if nmcli radio wifi | grep -q "enabled"; then
        SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2)
        if [ -n "$SSID" ]; then
            echo " $SSID"
        else
            echo " Searching"
        fi
    else
        echo " Off"
    fi
fi
