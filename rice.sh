#!/bin/bash

# Pick a random image from your Wallpapers folder
WALL=$(find ~/Pictures/Wallpapers -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | shuf -n 1)

if [ -z "$WALL" ]; then
    echo "ERROR: No wallpapers found in ~/Pictures/Wallpapers"
    exit 1
fi

echo ">>> Changing wallpaper to: $WALL"

# Apply it with SWWW (with a slick HyDE wipe transition)
swww img "$WALL" --transition-type wipe --transition-angle 30 --transition-step 90

# Generate the master color palette via Pywal
wal -i "$WALL" -n -q

# Tell all open Kitty terminals to live-reload the new colors
killall -SIGUSR1 kitty

echo ">>> System Riced Successfully!"
