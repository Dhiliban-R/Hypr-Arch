#!/bin/bash
# Check Caps Lock state from LED
# Note: The path might need adjustment if hardware changes, currently set to wildcard.

CAPS_STATE=$(cat /sys/class/leds/input*::capslock/brightness 2>/dev/null | head -n 1)

if [ "$CAPS_STATE" -eq 1 ]; then
    notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -i input-keyboard "Caps Lock" "ON"
else
    notify-send -h string:x-canonical-private-synchronous:sys-notify -u low -i input-keyboard "Caps Lock" "OFF"
fi
