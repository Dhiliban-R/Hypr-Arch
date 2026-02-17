#!/bin/bash

# $1: up, down, mute

# Send notification
if [[ "$1" == "mute" ]]; then
    # Toggle Mute
    pamixer -t
    if $(pamixer --get-mute); then
        /home/dhili/.local/bin/notify-system --type volume --state muted --text "Muted"
    else
        VOLUME=$(pamixer --get-volume)
        /home/dhili/.local/bin/notify-system --type volume --state "${VOLUME}" --text "${VOLUME}%"
    fi
else
    # Up / Down
    if [[ "$1" == "up" ]]; then
        pamixer -i 5
    elif [[ "$1" == "down" ]]; then
        pamixer -d 5
    fi
    
    VOLUME=$(pamixer --get-volume)
    /home/dhili/.local/bin/notify-system --type volume --state "${VOLUME}" --text "${VOLUME}%"
fi