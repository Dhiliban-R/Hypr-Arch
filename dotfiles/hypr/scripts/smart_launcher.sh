#!/bin/bash

# Define Log
LOG="/tmp/smart_launcher_debug.log"
exec 1>>"$LOG" 2>&1

# Config
CACHE="$HOME/.cache/gemini_apps_list"

# 10 Strong, Saturated Colors
COLORS=(
    "#9d4edd" # Royal Purple
    "#ff006e" # Hot Pink
    "#3a86ff" # Electric Blue
    "#00b341" # Strong Green
    "#fb5607" # Vivid Orange
    "#d90429" # Fire Red
    "#ffbe0b" # Deep Gold
    "#023e8a" # Deep Sea Blue
    "#c9184a" # Crimson Magenta
    "#008080" # Teal
)

# Build Cache Function
build_cache() {
    echo "Building Cyclic Color Cache..."
    notify-send "Launcher" "Updating App List..."
    
    TMP="/tmp/raw_apps"
    rm -f "$TMP"
    
    # Gather Apps
    find -L /usr/share/applications ~/.local/share/applications -name "*.desktop" 2>/dev/null | while read file; do
        if grep -q "^NoDisplay=true" "$file"; then continue; fi
        name=$(grep -m 1 "^Name=" "$file" | cut -d= -f2-)
        exec=$(grep -m 1 "^Exec=" "$file" | cut -d= -f2- | cut -d' ' -f1)
        if [ -n "$name" ] && [ -n "$exec" ]; then
            echo "$name|$exec"
        fi
    done | sort -u -t'|' -k1,1 > "$TMP"

    # Apply Colors Cyclically
    # We use awk to cycle strictly 1->10->1
    awk -v colors="${COLORS[*]}" ' 
    BEGIN {
        split(colors, c, " ");
        num_colors = 10; 
        i = 1;
        FS="|"; 
    }
    {
        if ($1 != "" && $2 != "") {
            # Sanitize
            name = $1;
            gsub(/&/, "&amp;", name);
            gsub(/</, "&lt;", name);
            gsub(/>/, "&gt;", name);
            
            # Apply Color [i]
            printf "<span foreground=\"%s\">%s</span>|%s|%s\n", c[i], name, $1, $2;
            
            # Increment and Wrap
            i = (i % num_colors) + 1;
        }
    }' "$TMP" > "$CACHE"
    
    rm "$TMP"
}

# Check Cache
if [ ! -f "$CACHE" ] || [ ! -s "$CACHE" ]; then
    build_cache
fi

# Run Wofi
# Cache Format: MarkupName|RealName|Exec
input=$(cut -d'|' -f1 "$CACHE" | wofi --dmenu --insensitive --allow-markup --prompt "Apps / s Search / c Calc / f Find" --lines 5 --width 400)

if [ -z "$input" ]; then
    exit 0
fi

# Match
match=$(grep -F -m 1 "$input|" "$CACHE")

if [ -n "$match" ]; then
    cmd=$(echo "$match" | cut -d'|' -f3)
    hyprctl dispatch exec "$cmd" &
    exit 0
fi

# Custom Triggers
trigger=$(echo "$input" | cut -d' ' -f1 | tr '[:upper:]' '[:lower:]')
query=$(echo "$input" | cut -d' ' -f2-)

if [ "$input" == "updt" ]; then
    wezterm start -- bash -c "paru -Syu; npm install -g @google/gemini-cli@nightly; sleep 5" &
    exit 0
fi

case "$trigger" in
    "c")
        result=$(python -c "print($query)" 2>/dev/null)
        [ -n "$result" ] && notify-send "Result: $result" && echo -n "$result" | wl-copy
        ;;
    "s")
        brave "https://search.brave.com/search?q=$query" &
        ;;
    "f")
        notify-send "Finding..." "$query"
        res=$(find ~ -maxdepth 4 -not -path '*/.*' -iname "*$query*" 2>/dev/null | wofi --dmenu --insensitive --prompt "Open File")
        [ -n "$res" ] && xdg-open "$res" &
        ;;
    "t")
        wezterm start -- $query &
        ;;
    *)
        hyprctl dispatch exec "$input" &
        ;;
esac