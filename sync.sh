#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

if ! command -v gum &> /dev/null; then
    echo "gum could not be found, installing it first..."
    if command -v pacman &> /dev/null; then
        sudo pacman -S --needed --noconfirm gum
    else
        echo "Error: gum is required but not installed. Please install gum first."
        exit 1
    fi
fi

LOGO="
 ▗▖  ▗▖▗▄▄▄▖▗▄▄▄▖▗▄▄▖  ▗▄▖      ▗▄▖  ▗▄▄▖
 ▐▛▚▖▐▌  █    █  ▐▌ ▐▌▐▌ ▐▌    ▐▌ ▐▌▐▌   
 ▐▌ ▝▜▌  █    █  ▐▛▀▚▖▐▌ ▐▌    ▐▌ ▐▌ ▝▀▚▖
 ▐▌  ▐▌▗▄█▄▖  █  ▐▌ ▐▌▝▚▄▞▘    ▝▚▄▞▘▗▄▄▞▘
 
         Github : @Nitro-OS
"
gum style --foreground 99 --border double --border-foreground 99 --align center --width 60 --padding "1 2" --margin "1" "$LOGO"

if ! gum confirm "Do you want to sync system configurations into this repository?"; then
    gum style --foreground 196 "Sync cancelled."
    exit 0
fi

CONFIGS=("alacritty" "btop" "fastfetch" "hypr" "mako" "rofi" "waybar")

gum style --foreground 99 "Select configuration targets to sync from system:"

AVAILABLE_ITEMS=()
for config in "${CONFIGS[@]}"; do
    if [ -d "$HOME/.config/$config" ]; then
        AVAILABLE_ITEMS+=("$config")
    fi
done

if [ -f "$HOME/.vimrc" ]; then
    AVAILABLE_ITEMS+=(".vimrc")
fi

if [ -f "$HOME/.local/share/fonts/nitroos.ttf" ] || [ -d "$HOME/.local/share/fonts" ]; then
    AVAILABLE_ITEMS+=("fonts")
fi

if [ ${#AVAILABLE_ITEMS[@]} -eq 0 ]; then
    gum style --foreground 196 "No supported configurations found in system ($HOME/.config)."
    exit 1
fi

CHOSEN_ITEMS=$(gum choose --no-limit --selected="*" --show-help --header="Select configs to sync (x / Space / Tab to toggle, Enter to confirm):" "${AVAILABLE_ITEMS[@]}")

if [ -z "$CHOSEN_ITEMS" ]; then
    gum style --foreground 214 "No items selected. Exiting."
    exit 0
fi

readarray -t SYNC_LIST <<< "$CHOSEN_ITEMS"

gum style --foreground 99 "Syncing configurations from system -> repository..."

for item in "${SYNC_LIST[@]}"; do
    [ -z "$item" ] && continue

    if [ "$item" = ".vimrc" ]; then
        if [ -f "$HOME/.vimrc" ]; then
            gum style --foreground 75 "Syncing file: $HOME/.vimrc -> .vimrc"
            cp -f "$HOME/.vimrc" "$SCRIPT_DIR/.vimrc"
        fi
    elif [ "$item" = "fonts" ]; then
        mkdir -p "$SCRIPT_DIR/fonts"
        if [ -f "$HOME/.local/share/fonts/nitroos.ttf" ]; then
            gum style --foreground 75 "Syncing font: $HOME/.local/share/fonts/nitroos.ttf -> fonts/"
            cp -f "$HOME/.local/share/fonts/nitroos.ttf" "$SCRIPT_DIR/fonts/"
        fi
    else
        src="$HOME/.config/$item"
        dest="$SCRIPT_DIR/$item"

        if [ -d "$src" ]; then
            gum style --foreground 75 "Syncing directory: $src -> $dest"
            mkdir -p "$dest"
            if command -v rsync &> /dev/null; then
                rsync -av --delete \
                    --exclude=".git" \
                    --exclude="*.sock" \
                    --exclude="*.log" \
                    --exclude=".cache" \
                    "$src/" "$dest/" > /dev/null
            else
                rm -rf "$dest"
                mkdir -p "$dest"
                cp -rf "$src"/. "$dest/"
            fi
        else
            gum style --foreground 214 "Source directory $src not found, skipping."
        fi
    fi
done

gum style --foreground 82 "Configurations successfully synced from system!"

gum style --foreground 82 "NitroHypr Sync completed!"
