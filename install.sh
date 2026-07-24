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

if ! gum confirm "Do you want to proceed with installing NitroHypr?"; then
    gum style --foreground 196 "Installation cancelled."
    exit 0
fi

gum style --foreground 99 "Select your preferred package helper:"
HELPERS=()
if command -v yay &> /dev/null; then
    HELPERS+=("yay")
else
    HELPERS+=("yay (install & configure)")
fi
if command -v paru &> /dev/null; then HELPERS+=("paru"); fi
HELPERS+=("pacman")

HELPER_CHOICE=$(gum choose "${HELPERS[@]}")
if [ -z "$HELPER_CHOICE" ]; then
    gum style --foreground 196 "No helper chosen. Exiting."
    exit 1
fi

if [[ "$HELPER_CHOICE" == *"yay"* ]]; then
    HELPER="yay"
    if ! command -v yay &> /dev/null; then
        gum style --foreground 99 "yay not found. Installing and configuring yay..."
        sudo pacman -S --needed --noconfirm git base-devel
        git clone https://aur.archlinux.org/yay.git /tmp/yay-build
        cd /tmp/yay-build
        makepkg -si --noconfirm
        cd "$SCRIPT_DIR"
        rm -rf /tmp/yay-build
        gum style --foreground 82 "yay installed and configured successfully!"
    fi
elif [ "$HELPER_CHOICE" = "paru" ]; then
    HELPER="paru"
else
    HELPER="pacman"
fi

gum style --foreground 82 "Selected package helper: $HELPER"

PACKAGES=()
if [ -f "packages.txt" ]; then
    while IFS= read -r line; do
        line=$(echo "$line" | sed 's/#.*//' | xargs)
        if [[ -n "$line" ]]; then
            PACKAGES+=("$line")
        fi
    done < "packages.txt"
else
    gum style --foreground 196 "packages.txt not found! Skipping package installation."
fi

if [ ${#PACKAGES[@]} -gt 0 ]; then
    CHOSEN_PACKAGES=$(gum choose --no-limit --selected="*" --header="Select packages to install (Space to toggle, Enter to confirm):" "${PACKAGES[@]}")
    
    if [ -n "$CHOSEN_PACKAGES" ]; then
        readarray -t TO_INSTALL <<< "$CHOSEN_PACKAGES"
        
        gum style --foreground 99 "Requesting sudo privileges for installation..."
        sudo -v
        
        gum style --foreground 99 "Installing packages..."
        if [ "$HELPER" = "pacman" ]; then
            sudo pacman -S --needed --noconfirm "${TO_INSTALL[@]}"
        else
            $HELPER -S --needed --noconfirm "${TO_INSTALL[@]}"
        fi
    else
        gum style --foreground 214 "No packages selected for installation."
    fi
fi

gum style --foreground 99 "Installing configuration files..."
CONFIGS=("alacritty" "fastfetch" "hypr" "mako" "rofi" "waybar")
mkdir -p "$HOME/.config"

for config in "${CONFIGS[@]}"; do
    if [ -d "$config" ]; then
        dest="$HOME/.config/$config"
        timestamp=$(date +%Y%m%d_%H%M%S)
        
        if [ -d "$dest" ] || [ -f "$dest" ]; then
            gum style --foreground 245 "Backing up existing $dest to ${dest}.bak.${timestamp}..."
            mv "$dest" "${dest}.bak.${timestamp}"
        fi
        
        gum style --foreground 75 "Installing configuration: $config -> $dest"
        cp -r "$config" "$HOME/.config/"
    else
        gum style --foreground 214 "Configuration folder $config not found in repository, skipping."
    fi
done

if gum confirm "Do you want to install NitroVim configuration?"; then
    dest="$HOME/.config/nvim"
    timestamp=$(date +%Y%m%d_%H%M%S)
    if [ -d "$dest" ] || [ -f "$dest" ]; then
        gum style --foreground 245 "Backing up existing $dest to ${dest}.bak.${timestamp}..."
        mv "$dest" "${dest}.bak.${timestamp}"
    fi
    gum style --foreground 75 "Cloning NitroVim configuration..."
    git clone https://github.com/NitroVim/NitroVim "$dest"
fi

if [ -d "fonts" ]; then
    gum style --foreground 99 "Installing fonts..."
    font_dir="$HOME/.local/share/fonts"
    mkdir -p "$font_dir"
    cp fonts/*.ttf "$font_dir/" 2>/dev/null || cp fonts/*.otf "$font_dir/" 2>/dev/null || true
    gum style --foreground 75 "Rebuilding font cache..."
    fc-cache -f
fi

gum style --foreground 82 --border double --border-foreground 82 --align center --width 60 --padding "1 2" \
  "NitroHypr installed successfully!" \
  "Please log out and log in choosing Hyprland session."
