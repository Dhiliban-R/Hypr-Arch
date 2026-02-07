#!/bin/bash

if swaync-client --get-dnd | grep -q "true"; then
    echo '{"text": "", "tooltip": "Do Not Disturb: ON", "class": "dnd-on"}'
else
    echo '{"text": "", "tooltip": "Do Not Disturb: OFF", "class": "dnd-off"}'
fi
