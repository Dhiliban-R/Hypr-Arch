#!/bin/bash

NOTIFY="/home/dhili/.local/bin/notify-system"

# Toggle DND using swaync-client
swaync-client --toggle-dnd

# Get the new DND state
NEW_DND_STATE=$(swaync-client --get-dnd)

if [ "$NEW_DND_STATE" = "true" ]; then
    $NOTIFY --type system --state dnd-on --text "Enabled"
else
    $NOTIFY --type system --state dnd-off --text "Disabled"
fi

# Refresh waybar module immediately
pkill -SIGRTMIN+11 waybar
