#!/bin/bash

# $1: up, down

ACTION=$1

if [ "$ACTION" == "up" ]; then
    brightnessctl set 5%+
    STYLE="style_green"
elif [ "$ACTION" == "down" ]; then
    brightnessctl set 5%-
    STYLE="style_red"
fi

# Get brightness percentage
BRIGHTNESS=$(brightnessctl -m | cut -d, -f4 | tr -d %)

notify-send -c "$STYLE" -h string:x-canonical-private-synchronous:sys-notify -u low -i display-brightness-symbolic "Brightness" "${BRIGHTNESS}%"