#!/bin/bash

NOTIFY="/home/dhili/.local/bin/notify-system"

# Check current mode
if makoctl mode | grep -q "dnd"; then
    makoctl mode -r dnd
    $NOTIFY --type system --state dnd-off --text "Disabled"
else
    # Show notification BEFORE enabling DND so the user sees it
    $NOTIFY --type system --state dnd-on --text "Enabled"
    
    # Small sleep to ensure the notification is rendered before mode switches
    sleep 0.1
    makoctl mode -a dnd
fi