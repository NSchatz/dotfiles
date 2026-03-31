#!/usr/bin/env bash
# Wallpaper slideshow using awww (swww)
# Cycles through all images in a directory with animated transitions

WALLPAPER_DIR="$HOME/Pictures/wallpapers/catppuccin-mocha"
INTERVAL=300  # seconds between changes (5 minutes)
TRANSITION_TYPE="fade"
TRANSITION_DURATION=2

# Get all image files
get_wallpapers() {
    find "$WALLPAPER_DIR" -type f \( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' -o -name '*.webp' \) | shuf
}

# If called with --next, just change to a random wallpaper and exit
if [[ "$1" == "--next" ]]; then
    WALL=$(find "$WALLPAPER_DIR" -type f \( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' -o -name '*.webp' \) | shuf -n 1)
    awww img "$WALL" --transition-type "$TRANSITION_TYPE" --transition-duration "$TRANSITION_DURATION"
    exit 0
fi

# Continuous slideshow loop
while true; do
    get_wallpapers | while IFS= read -r wall; do
        awww img "$wall" --transition-type "$TRANSITION_TYPE" --transition-duration "$TRANSITION_DURATION"
        sleep "$INTERVAL"
    done
done
