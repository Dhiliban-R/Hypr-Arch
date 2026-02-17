#!/bin/bash

# Get battery status and capacity
STATUS=$(cat /sys/class/power_supply/BAT1/status)
CAPACITY=$(cat /sys/class/power_supply/BAT1/capacity)

# Define icons
if [ "$STATUS" = "Charging" ]; then
    if [ "$CAPACITY" -ge 90 ]; then ICON="󰂅"
    elif [ "$CAPACITY" -ge 80 ]; then ICON="󰂄"
    elif [ "$CAPACITY" -ge 70 ]; then ICON="󰂃"
    elif [ "$CAPACITY" -ge 60 ]; then ICON="󰂂"
    elif [ "$CAPACITY" -ge 50 ]; then ICON="󰂁"
    elif [ "$CAPACITY" -ge 40 ]; then ICON="󰂀"
    elif [ "$CAPACITY" -ge 30 ]; then ICON="󰁿"
    elif [ "$CAPACITY" -ge 20 ]; then ICON="󰁾"
    elif [ "$CAPACITY" -ge 10 ]; then ICON="󰁽"
    else ICON="󰢜"
    fi
else
    if [ "$CAPACITY" -ge 90 ]; then ICON="󰁹"
    elif [ "$CAPACITY" -ge 80 ]; then ICON="󰂂"
    elif [ "$CAPACITY" -ge 70 ]; then ICON="󰂁"
    elif [ "$CAPACITY" -ge 60 ]; then ICON="󰂀"
    elif [ "$CAPACITY" -ge 50 ]; then ICON="󰁿"
    elif [ "$CAPACITY" -ge 40 ]; then ICON="󰁾"
    elif [ "$CAPACITY" -ge 30 ]; then ICON="󰁽"
    elif [ "$CAPACITY" -ge 20 ]; then ICON="󰁼"
    elif [ "$CAPACITY" -ge 10 ]; then ICON="󰁻"
    else ICON="󰁺"
    fi
fi

echo "$ICON $CAPACITY%"