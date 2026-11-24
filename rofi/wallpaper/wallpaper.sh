#!/bin/bash

WALL_DIR="$HOME/Pictures/NitroWalls"
CACHE="$HOME/.cache/current_wallpaper"
LOCK="$HOME/.cache/hyprlock_wallpaper"

if ! pidof awww-daemon >/dev/null; then
    awww-daemon &
    sleep 0.5
fi

SELECTED=$(
    find "$WALL_DIR" -type f | while read -r img; do
        [[ "$img" =~ \.(jpg|jpeg|png|webp|JPG|PNG)$ ]] || continue

        REL_PATH="${img#$WALL_DIR/}"

        printf "%s\0icon\x1f%s\n" "$REL_PATH" "$img"
    done | rofi \
        -dmenu \
        -i \
        -show-icons \
        -theme ~/.config/rofi/wallpaper/style.rasi \
        -p ""
)

if [[ -n "$SELECTED" ]]; then
    WALLPAPER="$WALL_DIR/$SELECTED"

    mkdir -p "$(dirname "$CACHE")"
    printf '%s\n' "$WALLPAPER" > "$CACHE"

    ln -sfnT "$WALLPAPER" "$LOCK"

    awww img "$WALLPAPER" \
        --transition-type random \
        --transition-duration 2 \
        --transition-fps 120
fi
