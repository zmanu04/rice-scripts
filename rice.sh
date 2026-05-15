#!/bin/bash

# 1. Core Configuration
EXTENSION_DIR="$HOME/src/rice-scripts/extensions"
WALL_DIR="$HOME/Pictures/Wallpapers"

# 2. Pick a random wallpaper
WALL=$(find "$WALL_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | shuf -n 1)

if [ -z "$WALL" ]; then
    echo "ERROR: No wallpapers found in $WALL_DIR"
    exit 1
fi

echo ">>> Orchestrator: Selected Wallpaper -> $(basename "$WALL")"

# 3. Apply the wallpaper image with SWWW globally
swww img "$WALL" --transition-type wipe --transition-angle 30 --transition-step 90 >/dev/null 2>&1 &

# 4. Extract core palette using Pywal
wal -i "$WALL" -n -q >/dev/null 2>&1

# 5. Modular Loop: Execute every active extension file
if [ -d "$EXTENSION_DIR" ]; then
    for ext in "$EXTENSION_DIR"/*; do
        if [ -x "$ext" ]; then
            echo ">>> Running Extension: $(basename "$ext")"
            "$ext" "$WALL" &
        fi
    done
fi

# 6. Sanitize and restore terminal viewport
sleep 0.4
stty sane
tput reset

echo ">>> Engine: System Riced Successfully!"
