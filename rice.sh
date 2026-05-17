#!/bin/bash

# 1. Core Configuration
EXTENSION_DIR="$HOME/src/rice-scripts/extensions"
WALL_DIR="$HOME/Pictures/Wallpapers"
CACHE_WALL_FILE="/tmp/current_wall"

# 2. Pick a random wallpaper
WALL=$(find "$WALL_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | shuf -n 1)

if [ -z "$WALL" ]; then
    echo "ERROR: No wallpapers found in $WALL_DIR"
    exit 1
fi

echo ">>> Orchestrator: Selected Wallpaper -> $(basename "$WALL")"

# Keep track of the old wallpaper before we swap it
if [ -f "$CACHE_WALL_FILE" ]; then
    OLD_WALL=$(cat "$CACHE_WALL_FILE")
else
    OLD_WALL="$WALL" # Fallback if script is run for the first time
fi

# 3. CRITICAL SPEEDUP: Convert the wallpaper into a tiny 200px thumbnail cache
THUMB="/tmp/wall_thumb.jpg"
magick "$WALL" -scale 200x200 "$THUMB"

# 4. Run Wallust on the tiny thumbnail FIRST
wallust run -s "$THUMB" >/dev/null 2>&1

# =====================================================================
# 5. The Sync Reset & Seeded Transition Loop
# =====================================================================
# Recycle the daemon to ensure the graphics pipeline is un-frozen
killall awww-daemon 2>/dev/null
rm -f "/run/user/$(id -u)/wayland-1-awww-daemon.sock"

# Spin up the fresh daemon instance
awww-daemon &
sleep 0.25 # Give it a brief split second to connect to the display

# STEP A: Feed the daemon the old wallpaper instantly so it has a reference frame.
# This happens with NO animation, meaning your screen won't flicker at all.
if [ -f "$OLD_WALL" ]; then
    awww img "$OLD_WALL" --transition-type none >/dev/null 2>&1
    sleep 0.1
fi

echo ">>> Applying wallpaper transition..."
# STEP B: Now that the daemon has a frame in memory, the wipe transition works!
# Isolated in a subshell () & disown to protect it from extension crashes.
(awww img "$WALL" \
    --transition-type wipe \
    --transition-angle 30 \
    --transition-step 10 \
    --transition-pos top-right >/dev/null 2>&1) &
disown

# Save the new wallpaper path for the next script cycle
echo "$WALL" > "$CACHE_WALL_FILE"

# =====================================================================
# 6. Modular Loop: Execute extensions sequentially
# =====================================================================
if [ -d "$EXTENSION_DIR" ]; then
    for ext in "$EXTENSION_DIR"/*; do
        if [ -x "$ext" ]; then
            echo ">>> Running Extension: $(basename "$ext")"
            "$ext" "$WALL" || true
        fi
    done
fi

echo ">>> Engine: System Riced Successfully!"
