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
    
    INSTALLED_PACKAGES=()
    for pkg in "${PACKAGES[@]}"; do
        if pacman -Qq "$pkg" &>/dev/null; then
            INSTALLED_PACKAGES+=("$pkg")
        fi
    done
    
    if [ ${#INSTALLED_PACKAGES[@]} -gt 0 ]; then
        if gum confirm "Do you want to uninstall the packages installed by NitroHypr?"; then
            CORE_HYPR_PACKAGES=("hyprland" "uwsm" "waybar" "rofi" "mako" "hyprpaper" "hyprlock" "hypridle" "hyprpicker" "hyprsunset" "waypaper" "swaybg" "grim" "slurp" "satty" "wl-clip-persist" "cliphist" "ghostty" "alacritty" "fastfetch")
            CORE_TO_UNINSTALL=()
            UTIL_TO_UNINSTALL=()
            
            for pkg in "${INSTALLED_PACKAGES[@]}"; do
                is_core=false
                for core_pkg in "${CORE_HYPR_PACKAGES[@]}"; do
                    if [ "$pkg" = "$core_pkg" ]; then
                        is_core=true
                        break
                    fi
                done
                if [ "$is_core" = true ]; then
                    CORE_TO_UNINSTALL+=("$pkg")
                else
                    UTIL_TO_UNINSTALL+=("$pkg")
                fi
            done
            
            FINAL_TO_UNINSTALL=()
            
            if [ ${#CORE_TO_UNINSTALL[@]} -gt 0 ]; then
                gum style --foreground 99 "Select Core Hyprland packages to remove:"
                CHOSEN_CORE=$(gum choose --no-limit --selected="*" --header="Core packages (Space to toggle, Enter to confirm):" "${CORE_TO_UNINSTALL[@]}")
                if [ -n "$CHOSEN_CORE" ]; then
                    readarray -t CHOSEN_CORE_ARR <<< "$CHOSEN_CORE"
                    for val in "${CHOSEN_CORE_ARR[@]}"; do
                        if [ -n "$val" ]; then
                            FINAL_TO_UNINSTALL+=("$val")
                        fi
                    done
                fi
            fi
            
            if [ ${#UTIL_TO_UNINSTALL[@]} -gt 0 ]; then
                gum style --foreground 214 "Warning: Removing system utilities (like networkmanager, pipewire, neovim, zsh) may affect other desktop environments or system behavior."
                if gum confirm "Do you want to review and remove utility/system packages?"; then
                    CHOSEN_UTIL=$(gum choose --no-limit --header="System utilities (Space to toggle, Enter to confirm):" "${UTIL_TO_UNINSTALL[@]}")
                    if [ -n "$CHOSEN_UTIL" ]; then
                        readarray -t CHOSEN_UTIL_ARR <<< "$CHOSEN_UTIL"
                        for val in "${CHOSEN_UTIL_ARR[@]}"; do
                            if [ -n "$val" ]; then
                                FINAL_TO_UNINSTALL+=("$val")
                            fi
                        done
                    fi
                fi
            fi
            
            if [ ${#FINAL_TO_UNINSTALL[@]} -gt 0 ]; then
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
                        sudo pacman -Rns --noconfirm "${FINAL_TO_UNINSTALL[@]}" || gum style --foreground 196 "Some packages could not be removed."
                    else
                        $HELPER -Rns --noconfirm "${FINAL_TO_UNINSTALL[@]}" || gum style --foreground 196 "Some packages could not be removed."
                    fi
                fi
            fi
        fi
    fi
fi

cleanup_dm_sessions() {
    gum style --foreground 99 "Cleaning up display manager session caches..."
    
    if [ -f "$HOME/.dmrc" ]; then
        if grep -q "Session=hyprland" "$HOME/.dmrc"; then
            sed -i '/^Session=hyprland/d' "$HOME/.dmrc" 2>/dev/null
            gum style --foreground 82 "Cleared Hyprland from ~/.dmrc"
        fi
    fi

    if [ -f "/var/lib/AccountsService/users/$USER" ]; then
        if grep -E -q "^(Session|XSession)=hyprland" "/var/lib/AccountsService/users/$USER"; then
            gum style --foreground 99 "Requesting sudo to reset GDM session cache..."
            sudo sed -i '/^Session=hyprland/d' "/var/lib/AccountsService/users/$USER" 2>/dev/null
            sudo sed -i '/^XSession=hyprland/d' "/var/lib/AccountsService/users/$USER" 2>/dev/null
            gum style --foreground 82 "Reset session settings in GDM/AccountsService for $USER"
            
            if systemctl is-active --quiet accounts-daemon; then
                sudo systemctl restart accounts-daemon 2>/dev/null
            fi
        fi
    fi

    if [ -f "/var/lib/sddm/state.conf" ]; then
        if grep -q "Session=hyprland" "/var/lib/sddm/state.conf"; then
            gum style --foreground 99 "Requesting sudo to reset SDDM session cache..."
            sudo sed -i 's/^Session=hyprland.*/Session=/' /var/lib/sddm/state.conf 2>/dev/null
            gum style --foreground 82 "Reset session settings in SDDM (/var/lib/sddm/state.conf)"
        fi
    fi

    if [ -f "/etc/lightdm/lightdm.conf" ]; then
        if grep -q "^user-session=hyprland" "/etc/lightdm/lightdm.conf"; then
            gum style --foreground 99 "Requesting sudo to reset LightDM session configuration..."
            sudo sed -i 's/^user-session=hyprland.*/#user-session=/g' /etc/lightdm/lightdm.conf 2>/dev/null
            gum style --foreground 82 "Reset session settings in LightDM"
        fi
    fi

    if ! pacman -Qq hyprland &>/dev/null; then
        for desktop_file in "/usr/share/wayland-sessions/hyprland.desktop" "/usr/share/wayland-sessions/hyprland-uwsm.desktop"; do
            if [ -f "$desktop_file" ]; then
                gum style --foreground 214 "Orphaned session file found: $desktop_file. Removing it..."
                sudo rm -f "$desktop_file" 2>/dev/null
            fi
        done
    fi
}

cleanup_dm_sessions

gum style --foreground 82 --border double --border-foreground 82 --align center --width 60 --padding "1 2" \
  "NitroHypr uninstalled successfully!"
