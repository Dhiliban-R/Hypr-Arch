#!/bin/bash
# Set PATH
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:$HOME/.local/bin

LOG_FILE="/tmp/ocr_debug.log"
TEMP_IMG=$(mktemp /tmp/ocr_XXXXXX.png)

exec > >(tee -a "$LOG_FILE") 2>&1
echo "--- OCR Tool Started at $(date) ---"

# 1. Capture Image
grim -g "$(slurp)" "$TEMP_IMG"
if [ ! -s "$TEMP_IMG" ]; then
    rm "$TEMP_IMG"
    exit 0
fi

# 2. Extract Text
notify-send "OCR Processing" "Extracting text..."
TEXT=$(tesseract "$TEMP_IMG" - 2>/dev/null)
rm "$TEMP_IMG"

if [ -z "$TEXT" ]; then
    notify-send "OCR Failed" "No text detected"
    exit 0
fi

# 3. Copy to Clipboard
echo "$TEXT" | wl-copy

# 4. Open Clipboard Manager
notify-send "OCR Complete" "Text copied to clipboard"
# Small delay to ensure cliphist registers the new entry before we list it
sleep 0.5 
~/.config/hypr/scripts/clipboard.sh
