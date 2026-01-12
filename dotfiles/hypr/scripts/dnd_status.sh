#!/bin/bash

if makoctl mode | grep -q "dnd"; then
    echo '{"text": "", "tooltip": "Do Not Disturb: ON", "class": "dnd-on"}'
else
    echo '{"text": "", "tooltip": "Do Not Disturb: OFF", "class": "dnd-off"}'
fi
