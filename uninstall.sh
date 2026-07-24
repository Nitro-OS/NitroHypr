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
gum style --foreground 125 --border double --border-foreground 125 --align center --width 60 --padding "1 2" --margin "1" "$LOGO"

if ! gum confirm "Are you sure you want to uninstall NitroHypr?"; then
    gum style --foreground 196 "Uninstallation cancelled."
    exit 0
fi

gum style --foreground 99 "Removing NitroHypr configurations..."
CONFIGS=("alacritty" "fastfetch" "hypr" "mako" "nvim" "rofi" "waybar")

for config in "${CONFIGS[@]}"; do
    dest="$HOME/.config/$config"
    if [ -d "$dest" ] || [ -f "$dest" ]; then
        if gum confirm "Remove $dest?"; then
            rm -rf "$dest"
            gum style --foreground 196 "Removed $dest"
        fi
    fi
done

font_file="$HOME/.local/share/fonts/nitroos.ttf"
if [ -f "$font_file" ]; then
    if gum confirm "Remove custom font nitroos.ttf?"; then
        rm "$font_file"
        gum style --foreground 196 "Removed $font_file"
        fc-cache -f
    fi
fi

restore_backups() {
    gum style --foreground 99 "Checking for backups to restore..."
    local restored_any=false
    for config in "${CONFIGS[@]}"; do
        dest="$HOME/.config/$config"
        local backups
        backups=($(find "$HOME/.config" -maxdepth 1 -name "${config}.bak.*" | sort -V 2>/dev/null || true))
        if [ ${#backups[@]} -gt 0 ]; then
            latest_backup="${backups[-1]}"
            if gum confirm "Found backup: $(basename "$latest_backup"). Restore it?"; then
                rm -rf "$dest"
                mv "$latest_backup" "$dest"
                gum style --foreground 82 "Restored $dest from $(basename "$latest_backup")"
                restored_any=true
            fi
        fi
    done
    if [ "$restored_any" = false ]; then
        gum style --foreground 245 "No backups were restored."
    fi
}

restore_backups

if [ -f "packages.txt" ]; then
    PACKAGES=()
    while IFS= read -r line; do
        line=$(echo "$line" | sed 's/#.*//' | xargs)
        if [[ -n "$line" ]]; then
            PACKAGES+=("$line")
        fi
    done < "packages.txt"
    
    if [ ${#PACKAGES[@]} -gt 0 ]; then
        if gum confirm "Do you want to uninstall the packages installed by NitroHypr?"; then
            CHOSEN_PACKAGES=$(gum choose --no-limit --selected="*" --header="Select packages to uninstall (Space to toggle, Enter to confirm):" "${PACKAGES[@]}")
            
            if [ -n "$CHOSEN_PACKAGES" ]; then
                readarray -t TO_UNINSTALL <<< "$CHOSEN_PACKAGES"
                gum style --foreground 99 "Requesting sudo privileges for package removal..."
                sudo -v
                
                HELPERS=()
                if command -v yay &> /dev/null; then HELPERS+=("yay"); fi
                if command -v paru &> /dev/null; then HELPERS+=("paru"); fi
                HELPERS+=("pacman")
                
                HELPER=$(gum choose --header="Choose helper to uninstall with:" "${HELPERS[@]}")
                if [ -n "$HELPER" ]; then
                    gum style --foreground 99 "Removing packages..."
                    if [ "$HELPER" = "pacman" ]; then
                        sudo pacman -Rns --noconfirm "${TO_UNINSTALL[@]}" || gum style --foreground 196 "Some packages could not be removed."
                    else
                        $HELPER -Rns --noconfirm "${TO_UNINSTALL[@]}" || gum style --foreground 196 "Some packages could not be removed."
                    fi
                fi
            fi
        fi
    fi
fi

gum style --foreground 82 --border double --border-foreground 82 --align center --width 60 --padding "1 2" \
  "NitroHypr uninstalled successfully!"
