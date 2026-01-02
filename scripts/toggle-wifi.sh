#!/bin/bash
WIFI_STATUS=$(nmcli radio wifi)
if [ "$WIFI_STATUS" = "enabled" ]; then
    nmcli radio wifi off
else
    nmcli radio wifi on
fi
