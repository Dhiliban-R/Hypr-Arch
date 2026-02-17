#!/bin/bash

# $1: up, down

ACTION=$1

if [ "$ACTION" == "up" ]; then
    brightnessctl set 5%+
elif [ "$ACTION" == "down" ]; then
    brightnessctl set 5%-
fi

# Get brightness percentage
BRIGHTNESS=$(brightnessctl -m | cut -d, -f4 | tr -d %)

/home/dhili/.local/bin/notify-system --type brightness --state "${BRIGHTNESS}" --text "${BRIGHTNESS}%"