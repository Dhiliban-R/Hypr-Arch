#!/bin/bash

# =============================================================================
# cliphist-thumbnailer.sh: Generate thumbnails for cliphist entries in wofi
# =============================================================================

entry="$1"

# If it's the Clear History option, just return it as is
if [[ "$entry" == *"Clear History"* ]]; then
    echo "$entry"
    exit 0
fi

id=$(echo "$entry" | cut -f1)
content=$(echo "$entry" | cut -f2-)

# Cache directory for thumbnails
CACHE_DIR="$HOME/.cache/cliphist/thumbnails"
mkdir -p "$CACHE_DIR"

# If it's binary data (image)
if [[ "$content" == *"[[ binary data"* ]]; then
    thumb="$CACHE_DIR/${id}.png"
    # Create thumbnail if it doesn't exist
    if [ ! -f "$thumb" ]; then
        cliphist decode "$id" > "$thumb" 2>/dev/null
    fi
    # Return wofi image format
    echo "img:$thumb:$content"
else
    # Return plain text for everything else
    echo "$content"
fi