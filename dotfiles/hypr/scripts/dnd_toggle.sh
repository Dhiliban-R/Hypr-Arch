#!/bin/bash

# Check current mode
if makoctl mode | grep -q "dnd"; then
    makoctl mode -r dnd
    notify-send "Do Not Disturb" "Disabled" -u low -t 2000
else
    makoctl mode -a dnd
    # No notification here because DND is now active and it would be hidden anyway
    # But we can force one if we really want, or just rely on the bar icon
fi
