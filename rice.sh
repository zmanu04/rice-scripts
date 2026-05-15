#!/bin/bash

# Pick a random image from your Wallpapers folder
WALL=$(find ~/Pictures/Wallpapers -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | shuf -n 1)

if [ -z "$WALL" ]; then
    echo "ERROR: No wallpapers found in ~/Pictures/Wallpapers"
    exit 1
fi

echo ">>> Changing wallpaper to: $(basename "$WALL")"

# 1. Apply it with SWWW (silenced completely)
swww img "$WALL" --transition-type wipe --transition-angle 30 --transition-step 90 >/dev/null 2>&1 &

# 2. Generate the master color palette via Pywal (silenced entirely)
wal -i "$WALL" -n -q >/dev/null 2>&1

# 3. Tell all open Kitty terminals to live-reload the new colors
killall -SIGUSR1 kitty

# 4. Give Kitty half a second to finish painting the new background scheme
sleep 0.5

# 5. Forcefully sanitize and reset the terminal state to fix the offset text bug
stty sane
tput reset

echo ">>> System Riced Successfully!"
