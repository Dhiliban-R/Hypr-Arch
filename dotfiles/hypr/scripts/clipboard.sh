#!/bin/bash

# =============================================================================
# clipboard.sh: FINAL UNBREAKABLE VERSION (V6 - Robustness Update)
# =============================================================================

STYLE="$HOME/.config/wofi/clipboard.css"
CACHE_DIR="$HOME/.cache/cliphist/thumbnails"
mkdir -p "$CACHE_DIR"

# 1. Check if cliphist is even working
if ! command -v cliphist &> /dev/null; then
    ~/.local/bin/notify-system --type clipboard --state error --text "cliphist is not installed"
    exit 1
fi

# 2. Get history
raw_list=$(cliphist list)

# If history is empty, don't just quit—check if the watcher is even running!
if [ -z "$raw_list" ]; then
    if ! pgrep -x "wl-paste" > /dev/null; then
        ~/.local/bin/notify-system --type clipboard --state error --text "Watchers are not running! Restarting..."
        ~/.config/hypr/scripts/cliphist-init.sh & 
        sleep 0.5
    fi
    # Check again
    raw_list=$(cliphist list)
    if [ -z "$raw_list" ]; then
        ~/.local/bin/notify-system --type clipboard --state error --text "History is empty. Copy something first!"
        exit 0
    fi
fi

# 3. Build Menu
final_menu=""
while read -r line; do
    [ -z "$line" ] && continue
    
    # Use safer ID extraction
    id=$(echo "$line" | awk '{print $1}' | grep -oE '[0-9]+')
    content=$(echo "$line" | cut -f2-)
    
    if [[ "$content" == *"[[ binary data"* ]]; then
        thumb="$CACHE_DIR/$id.png"
        if [ ! -f "$thumb" ]; then
            (cliphist decode "$id" > "$thumb" 2>/dev/null) & 
            final_menu+="\n$line"
        else
            final_menu+="\nimg:$thumb:text:$line"
        fi
    else
        final_menu+="\n$line"
    fi
done <<< "$raw_list"

# 4. Show Wofi
selected=$(echo -e "󰃢 Clear History$final_menu" | wofi --dmenu --width 800 --height 500 --style "$STYLE" --allow-images --prompt "Search Clipboard...")

if [ -z "$selected" ]; then
    exit 0
fi

if [[ "$selected" == *"󰃢 Clear History"* ]]; then
    cliphist wipe
    rm -rf "$CACHE_DIR"/*
    ~/.local/bin/notify-system --type clipboard --state cleared --text "History cleared"
    exit 0
fi

# 5. Extract Original Line
if [[ "$selected" == img:* ]]; then
    # Wofi adds img:...:text: to the front
    original_line=$(echo "$selected" | sed 's/^img:.*:text://')
else
    original_line="$selected"
fi

id=$(echo "$original_line" | awk '{print $1}' | grep -oE '[0-9]+' | head -n 1)

if [ -z "$id" ]; then
    exit 0
fi

# 6. Action
action=$(echo -e "󰆑 Paste\n󰆴 Delete" | wofi --dmenu --width 250 --height 160 --style "$STYLE" --prompt "Action?" --lines 2)

case "$action" in
    *Paste)
        if [[ "$original_line" == *"[[ binary data"* ]]; then
            tmp_file="/tmp/cliphist_decode_$id"
            cliphist decode "$id" > "$tmp_file"
            mime_type=$(file --mime-type -b "$tmp_file")
            wl-copy --type "$mime_type" < "$tmp_file"
            rm "$tmp_file"
            sleep 0.4
            wtype -M ctrl v -m ctrl
        else
            cliphist decode "$id" | wl-copy --type text/plain
            sleep 0.2
            wtype -M ctrl v -m ctrl
        fi
        ;; 
    *Delete)
        echo "$original_line" | cliphist delete
        rm -f "$CACHE_DIR/$id.png"
        ~/.local/bin/notify-system --type clipboard --state deleted --text "Item deleted"
        ;; 
    *)
        exit 0
        ;; 
esac
