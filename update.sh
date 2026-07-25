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

if ! gum confirm "Do you want to update NitroHypr?"; then
    gum style --foreground 196 "Update cancelled."
    exit 0
fi

gum style --foreground 99 "Pulling latest changes from git repository..."
if [ -d ".git" ]; then
    if git pull; then
        gum style --foreground 82 "Git repository updated successfully."
    else
        gum style --foreground 196 "Failed to pull from git repository. Proceeding with local updates..."
    fi
else
    gum style --foreground 214 "Not a git repository or git not initialized. Skipping git pull."
fi

if gum confirm "Do you want to apply the updated configurations to ~/.config/?"; then
    CONFIGS=("alacritty" "fastfetch" "hypr" "mako" "rofi" "waybar")
    mkdir -p "$HOME/.config"
    
    for config in "${CONFIGS[@]}"; do
        if [ -d "$config" ]; then
            dest="$HOME/.config/$config"
            
            gum style --foreground 75 "Updating configuration: $config -> $dest"
            if [ -f "$dest" ] && [ ! -d "$dest" ]; then
                rm -f "$dest"
            fi
            mkdir -p "$dest"
            cp -rf "$config"/. "$dest/"
        fi
    done
    
    if [ -d "fonts" ]; then
        font_dir="$HOME/.local/share/fonts"
        mkdir -p "$font_dir"
        cp fonts/*.ttf "$font_dir/" 2>/dev/null || cp fonts/*.otf "$font_dir/" 2>/dev/null || true
        fc-cache -f
    fi
    gum style --foreground 82 "Configurations updated."
fi

if [ -d "$HOME/.config/nvim/.git" ]; then
    if gum confirm "Do you want to update NitroVim configuration?"; then
        gum style --foreground 99 "Updating NitroVim..."
        git -C "$HOME/.config/nvim" pull
    fi
fi

if gum confirm "Do you want to update your system packages?"; then
    HELPERS=()
    if command -v yay &> /dev/null; then HELPERS+=("yay"); fi
    if command -v paru &> /dev/null; then HELPERS+=("paru"); fi
    HELPERS+=("pacman")
    
    HELPER=$(gum choose --header="Select package helper to update system:" "${HELPERS[@]}")
    if [ -n "$HELPER" ]; then
        gum style --foreground 99 "Updating system packages via $HELPER..."
        if [ "$HELPER" = "pacman" ]; then
            sudo pacman -Syu
        else
            $HELPER -Syu
        fi
    fi
fi

gum style --foreground 82 --border double --border-foreground 82 --align center --width 60 --padding "1 2" \
  "NitroHypr Update completed!"
