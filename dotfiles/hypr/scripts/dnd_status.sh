#!/bin/bash

if makoctl mode 2>/dev/null | grep -q "dnd"; then
    echo '{"text": "", "tooltip": "Do Not Disturb: ON", "class": "dnd-on"}'
else
    echo '{"text": "", "tooltip": "Do Not Disturb: OFF", "class": "dnd-off"}'
fi
