#!/bin/bash

# $1: up, down, mute

ACTION=$1

if [ "$ACTION" == "up" ]; then
    pamixer -i 5
    STYLE="style_green"
elif [ "$ACTION" == "down" ]; then
    pamixer -d 5
    STYLE="style_red"
elif [ "$ACTION" == "mute" ]; then
    pamixer -t
    STYLE="style_red"
fi

VOLUME=$(pamixer --get-volume)
IS_MUTED=$(pamixer --get-mute)

if [ "$IS_MUTED" == "true" ]; then
    notify-send -c style_red -h string:x-canonical-private-synchronous:sys-notify -u low -i audio-volume-muted "Volume" "Muted"
else
    # If unmuted, use style based on action (up=green, down=red)
    # If action was mute toggling to unmute, let's make it green
    if [ "$ACTION" == "mute" ]; then
         STYLE="style_green"
    fi
    notify-send -c "$STYLE" -h string:x-canonical-private-synchronous:sys-notify -u low -i audio-volume-high "Volume" "${VOLUME}%"
fi