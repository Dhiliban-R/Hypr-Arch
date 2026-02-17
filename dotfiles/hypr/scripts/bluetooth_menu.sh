#!/bin/bash

# Configuration
LOCK_FILE="/tmp/gemini_bt_autoscan.lock"
SCAN_TIMEOUT=5

show_menu() {
    # 1. Scanning Logic
    if [ -f "$LOCK_FILE" ]; then
        if ! bluetoothctl show | grep -q "Discovering: yes"; then
            bluetoothctl scan on > /dev/null 2>&1 &
        fi
    fi

    # 2. Get Device List
    devices=$(bluetoothctl devices | cut -d ' ' -f 3-)
    
    # 3. Check Power State
    power_state=$(bluetoothctl show | grep "Powered: yes")
    
    # 4. Build Options
    if [ -n "$power_state" ]; then
        # ON State
        toggle_opt="Turn Bluetooth OFF"
        manager_opt="Open Manager"
        
        if [ -f "$LOCK_FILE" ]; then
            autoscan_opt="[x] Auto-Scan (Active)"
            prompt="Bluetooth (Scanning...)"
        else
            autoscan_opt="[ ] Auto-Scan (Disabled)"
            prompt="Bluetooth"
        fi
        
        if [ -z "$devices" ]; then
            options="$manager_opt\n$toggle_opt\n$autoscan_opt"
        else
            options="$devices\n$manager_opt\n$toggle_opt\n$autoscan_opt"
        fi
    else
        # OFF State
        options="Turn Bluetooth ON"
        prompt="Bluetooth (OFF)"
    fi

    # 5. Show Wofi
    # UPDATED: Reduced lines to 5
    if [ -f "$LOCK_FILE" ] && [ -n "$power_state" ]; then
        selected=$(echo -e "$options" | timeout $SCAN_TIMEOUT wofi --dmenu --prompt "$prompt" --lines 5 --width 400)
        exit_code=$?
    else
        selected=$(echo -e "$options" | wofi --dmenu --prompt "$prompt" --lines 5 --width 400)
        exit_code=$?
    fi

    # 6. Handle Exit Codes
    if [ $exit_code -eq 124 ]; then
        show_menu
        return
    fi
    
    if [ $exit_code -ne 0 ]; then
        rm -f "$LOCK_FILE"
        bluetoothctl scan off > /dev/null 2>&1 &
        exit 0
    fi

    # 7. Logic
    if [ "$selected" == "Turn Bluetooth OFF" ]; then
        bluetoothctl power off
        rm -f "$LOCK_FILE"
        /home/dhili/.local/bin/notify-system --type bluetooth --state off --text "Powered OFF"
        
    elif [ "$selected" == "Turn Bluetooth ON" ]; then
        rfkill unblock bluetooth
        sleep 0.5
        bluetoothctl power on
        /home/dhili/.local/bin/notify-system --type bluetooth --state on --text "Powered ON"
        touch "$LOCK_FILE"
        bluetoothctl scan on > /dev/null 2>&1 &
        sleep 1
        show_menu
        
    elif [ "$selected" == "[ ] Auto-Scan (Disabled)" ]; then
        touch "$LOCK_FILE"
        show_menu
        
    elif [ "$selected" == "[x] Auto-Scan (Active)" ]; then
        rm -f "$LOCK_FILE"
        bluetoothctl scan off > /dev/null 2>&1 &
        show_menu
        
    elif [ "$selected" == "Open Manager" ]; then
        rm -f "$LOCK_FILE"
        blueman-manager &
        
    elif [ -n "$selected" ]; then
        rm -f "$LOCK_FILE"
        bluetoothctl scan off > /dev/null 2>&1 &
        
        mac=$(bluetoothctl devices | grep "$selected" | cut -d ' ' -f 2)
        
        if [ -n "$mac" ]; then
            info=$(bluetoothctl info "$mac" | grep "Connected: yes")
            if [ -n "$info" ]; then
                 /home/dhili/.local/bin/notify-system --type bluetooth --state connected --text "Disconnecting $selected..."
                 bluetoothctl disconnect "$mac"
                 /home/dhili/.local/bin/notify-system --type bluetooth --state disconnected --text "Disconnected"
                 
                 # Enforce Loop on Disconnect
                 touch "$LOCK_FILE"
                 sleep 1
                 show_menu
            else
                 /home/dhili/.local/bin/notify-system --type bluetooth --state searching --text "Connecting to $selected..."
                 if bluetoothctl connect "$mac"; then
                     /home/dhili/.local/bin/notify-system --type bluetooth --state connected --text "Connected"
                     # Enforce Break Loop on Connect
                     rm -f "$LOCK_FILE"
                     exit 0
                 else
                     /home/dhili/.local/bin/notify-system --type bluetooth --state disconnected --text "Failed to connect"
                     show_menu
                 fi
            fi
        fi
    fi
}

show_menu