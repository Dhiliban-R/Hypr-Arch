#!/bin/bash

# Configuration
LOCK_FILE="/tmp/gemini_wifi_autoscan.lock"
SCAN_TIMEOUT=5  # Reduced timeout for snappier loops if auto-scan is on

# Function to handle the menu loop
show_menu() {
    # 1. Scanning Logic (Only if Auto-Scan is ON)
    if [ -f "$LOCK_FILE" ]; then
        nmcli device wifi rescan &
        # No sleep here, we want to show the menu immediately with whatever we have
    fi

    # 2. Get List of Networks
    # OPTIMIZATION: Added '--rescan no' to make the menu appear INSTANTLY.
    # If you need to find new networks, enable Auto-Scan.
    wifi_list=$(nmcli -f "IN-USE,SSID,SECURITY,BARS" -t device wifi list --rescan no | \
                awk -F: '$2 != "" && !seen[$2]++ { 
                    if ($1 == "*") {
                        printf "%s [Connected]   (%s)   %s\n", $2, $3, $4
                    } else {
                        printf "%s   (%s)   %s\n", $2, $3, $4
                    }
                }')

    # 3. Check Power State
    state=$(nmcli radio wifi)
    
    # 4. Build Options
    if [ "$state" == "enabled" ]; then
        toggle_opt="Turn Wi-Fi OFF"
        
        # Auto-Scan Toggle Option
        if [ -f "$LOCK_FILE" ]; then
            autoscan_opt="[x] Auto-Scan (Active)"
            prompt="Wi-Fi (Scanning...)"
        else
            autoscan_opt="[ ] Auto-Scan (Disabled)"
            prompt="Wi-Fi Network"
        fi
        
        if [ -z "$wifi_list" ]; then
            options="$toggle_opt\n$autoscan_opt"
        else
            options="$wifi_list\n$toggle_opt\n$autoscan_opt"
        fi
    else
        # OFF State
        options="Turn Wi-Fi ON"
        prompt="Wi-Fi (OFF)"
    fi

# Show Wofi Menu
    if [ -f "$LOCK_FILE" ] && [ "$state" == "enabled" ]; then
        selected=$(echo -e "$options" | timeout $SCAN_TIMEOUT wofi --dmenu --prompt "$prompt" --lines 5 --width 400)
        exit_code=$?
    else
        selected=$(echo -e "$options" | wofi --dmenu --prompt "$prompt" --lines 5 --width 400)
        exit_code=$?
    fi

    # 6. Handle Exit Codes & Selection
    
    # Timeout (124) -> Loop
    if [ $exit_code -eq 124 ]; then
        show_menu
        return
    fi
    
    # User Cancelled (Esc) -> Cleanup and Exit
    if [ $exit_code -ne 0 ]; then
        rm -f "$LOCK_FILE"
        exit 0
    fi

    # 7. Logic for Selections
    if [ "$selected" == "Turn Wi-Fi OFF" ]; then
        nmcli radio wifi off
        rm -f "$LOCK_FILE"
        /home/dhili/.local/bin/notify-system --type wifi --state off --text "Turned OFF"
        
    elif [ "$selected" == "Turn Wi-Fi ON" ]; then
        nmcli radio wifi on
        /home/dhili/.local/bin/notify-system --type wifi --state on --text "Turned ON"
        # Enable Auto-Scan by default on power up so lists populate
        touch "$LOCK_FILE"
        show_menu
        
    elif [ "$selected" == "[ ] Auto-Scan (Disabled)" ]; then
        touch "$LOCK_FILE"
        show_menu
        
    elif [ "$selected" == "[x] Auto-Scan (Active)" ]; then
        rm -f "$LOCK_FILE"
        show_menu
        
    elif [ -n "$selected" ]; then
        # Network Selected -> Stop Auto-Scan
        rm -f "$LOCK_FILE"
        
        # Extract SSID
        ssid=$(echo "$selected" | sed 's/ \[Connected\]//' | sed 's/   .*//')
        
        # Check if connected
        if echo "$selected" | grep -q "\[Connected\]"; then
            /home/dhili/.local/bin/notify-system --type wifi --state searching --text "Disconnecting from $ssid..."
            interface=$(nmcli -t -f DEVICE,TYPE device | grep ":wifi$" | cut -d: -f1 | head -n1)
            nmcli device disconnect "$interface"
            /home/dhili/.local/bin/notify-system --type wifi --state disconnected --text "Disconnected"
            
            # Restart Auto-Scan after disconnect
            touch "$LOCK_FILE"
            show_menu
        else
            /home/dhili/.local/bin/notify-system --type wifi --state searching --text "Connecting to: $ssid"
            
            # Connection Logic with Fallback
            if nmcli device wifi connect "$ssid"; then
                /home/dhili/.local/bin/notify-system --type wifi --state connected --text "Connected to $ssid"
            else
                # Password Prompt Fallback
                password=$(echo "" | wofi --dmenu --password --prompt "Password for $ssid" --lines 1 --width 300 | tr -d '\n')
                if [ -n "$password" ]; then
                     nmcli connection delete id "$ssid" > /dev/null 2>&1
                     if nmcli device wifi connect "$ssid" password "$password"; then
                         /home/dhili/.local/bin/notify-system --type wifi --state connected --text "Connected to $ssid"
                     else
                         /home/dhili/.local/bin/notify-system --type wifi --state disconnected --text "Connection failed."
                     fi
                fi
            fi
        fi
    fi
}

# Start the loop
show_menu