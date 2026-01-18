#!/bin/bash
# Set PATH
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:$HOME/.local/bin

LOG_FILE="/tmp/ocr_debug.log"
SCRATCHPAD="/tmp/ocr_scratchpad.txt"
TEMP_IMG=$(mktemp /tmp/ocr_XXXXXX.png)
# We use a custom class to identify the window easily
WINDOW_CLASS="ocr_window"
WORKSPACE_NAME="ocr-workspace"

exec > >(tee -a "$LOG_FILE") 2>&1
echo "--- OCR Tool Started at $(date) ---"

touch "$SCRATCHPAD"

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

# 4. Handle Window
# Check if a wezterm pane in our specific workspace exists
# We filter by the workspace name we assign
PANE_ID=$(wezterm cli list | awk -v ws="$WORKSPACE_NAME" '$4 == ws {print $3; exit}')

if [ -z "$PANE_ID" ]; then
    echo "Starting new OCR window..."
    
    # Write text to file first
    if [ -s "$SCRATCHPAD" ]; then
        echo -e "\n\n" >> "$SCRATCHPAD"
    fi
    echo "$TEXT" >> "$SCRATCHPAD"
    
    # Launch new process with specific class and workspace
    # Using --always-new-process to ensure it pops up as a separate OS window
    wezterm start --always-new-process \
        --class "$WINDOW_CLASS" \
        --workspace "$WORKSPACE_NAME" \
        -- nano +999999 "$SCRATCHPAD" &
        
    notify-send "OCR Complete" "Opened new window"
else
    echo "Using existing pane: $PANE_ID"
    
    # Activate pane and workspace
    wezterm cli activate-pane --pane-id "$PANE_ID"
    wezterm cli activate-workspace --workspace "$WORKSPACE_NAME" 2>/dev/null
    
    # Send gap and text
    echo -e "\n\n" | wezterm cli send-text --pane-id "$PANE_ID" --no-paste
    echo "$TEXT" | wezterm cli send-text --pane-id "$PANE_ID"
    
    notify-send "OCR Complete" "Appended to existing window"
fi
