#!/bin/bash

# ENSURE NOTIFICATION WORKS IN BACKGROUND
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"

# Tools
HYPRCTL="/usr/bin/hyprctl"
NOTIFY="/home/dhili/.local/bin/notify-system"
PYTHON="/usr/bin/python3"

# Helper to get state
get_caps_state() {
    $HYPRCTL -j devices | $PYTHON -c "
import sys, json
try:
    data = json.load(sys.stdin)
    kbs = data.get('keyboards', [])
    caps = False
    for k in kbs:
        if k.get('capsLock') is True:
            caps = True
            break
    print('1' if caps else '0')
except:
    print('error')
"
}

# Wait for system to settle
sleep 2

# Initial State
LAST_STATE=$(get_caps_state)

while true; do
    CURRENT_STATE=$(get_caps_state)
    
    if [ "$CURRENT_STATE" != "error" ] && [ "$CURRENT_STATE" != "$LAST_STATE" ]; then
        if [ "$CURRENT_STATE" == "1" ]; then
            # ON
            $NOTIFY --type capslock --state on --text "ON"
        else
            # OFF
            $NOTIFY --type capslock --state off --text "OFF"
        fi
        LAST_STATE=$CURRENT_STATE
        sleep 0.2
    fi
    sleep 0.05
done