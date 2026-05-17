#!/bin/bash

# 1. Core Configuration
EXTENSION_DIR="$HOME/src/rice-scripts/extensions"
WALL_DIR="$HOME/Pictures/Wallpapers"
STATIC_WALL="/tmp/current_wallpaper.png"

# 2. Pick a random wallpaper
WALL=$(find "$WALL_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | shuf -n 1)

if [ -z "$WALL" ]; then
    echo "ERROR: No wallpapers found in $WALL_DIR"
    exit 1
fi

echo ">>> Orchestrator: Selected Wallpaper -> $(basename "$WALL")"

# 3. CRITICAL SPEEDUP: Convert the wallpaper into a tiny 200px thumbnail cache
THUMB="/tmp/wall_thumb.jpg"
magick "$WALL" -scale 200x200 "$THUMB"

# 4. Run Wallust on the tiny thumbnail FIRST
wallust run -s "$THUMB" >/dev/null 2>&1

# =====================================================================
# 5. INTANT SMART MULTI-MONITOR TRANSITION (Bypasses Fullscreen Locks)
# =====================================================================
# Ensure the daemon is running natively
if ! pgrep -x "awww-daemon" >/dev/null; then
    rm -f "/run/user/$(id -u)/wayland-1-awww-daemon.sock"
    WAYLAND_DISPLAY=wayland-1 awww-daemon &
    sleep 0.2
fi

echo ">>> Applying wallpaper transition..."

# 1. Parse Hyprland's monitor layouts to build a list of monitors to update.
# This filters out any monitor that currently has an active fullscreen window (hasFullscreen: true).
SAFE_MONITORS=$(hyprctl monitors -j | jq -r '.[] | select(.fullscreen == false) | .name' | tr '\n' ',' | sed 's/,$//')

# 2. If we found open, safe monitors, target them simultaneously
if [ -n "$SAFE_MONITORS" ]; then
    (
        WAYLAND_DISPLAY=wayland-1 awww img "$WALL" \
            --outputs "$SAFE_MONITORS" \
            --transition-type wipe \
            --transition-angle 30 \
            --transition-step 12 \
            --transition-pos top-right >/dev/null 2>&1
    ) &
    disown
else
    # Fallback to all screens if everything is fullscreen or jq parsing fails
    (
        WAYLAND_DISPLAY=wayland-1 awww img "$WALL" \
            --transition-type wipe \
            --transition-angle 30 \
            --transition-step 12 \
            --transition-pos top-right >/dev/null 2>&1
    ) &
    disown
fi

# Cache a copy to a static path
cp "$WALL" "$STATIC_WALL"

# =====================================================================
# 6. Modular Loop: Execute extensions concurrently
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
