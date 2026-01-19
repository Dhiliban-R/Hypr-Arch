#!/bin/bash
# cliphist-init.sh: Robustly start clipboard watchers

# 1. Kill any existing instances to prevent duplicates/conflicts
# Matches "wl-paste ... cliphist store"
pkill -f "wl-paste.*cliphist store" 2>/dev/null

# 2. Start separate watchers
# Use generic watcher for text/content
nohup wl-paste --watch cliphist store >/dev/null 2>&1 &
# Use specific image watcher
nohup wl-paste --type image --watch cliphist store >/dev/null 2>&1 &

