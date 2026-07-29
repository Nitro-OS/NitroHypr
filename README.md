# NitroHypr | Nitro OS Desktop

<img width="1920" height="1079" alt="image" src="https://github.com/user-attachments/assets/948f7602-b03a-4a4c-99b3-cadbd376fda8" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/ebfa3b1a-194b-4f97-a3fd-f0571b04eaa2" />
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/4650aa89-810b-451e-a43d-60a29f84b41c" />

NitroHypr is a modern, premium, and fully-featured Hyprland configuration suite designed for Arch Linux. It provides a polished and aesthetically stunning out-of-the-box tiling window manager experience with essential plugins and system utilities.

## Features
- **Window Manager**: Hyprland with UWSM support for clean Wayland session management.
- **Top Bar**: Custom, informative Waybar configurations.
- **Application Launcher**: Styled Rofi layouts for apps and menus.
- **Notification Daemon**: Light and beautiful Mako notifications.
- **Terminal Emulator**: Alacritty with custom styles.
- **System Info**: Sleek Fastfetch configurations.
- **Fonts**: Pre-configured high-quality Nerd Fonts.
- **Optional Editor**: Integrated with NitroVim for Neovim developers.

---

## Installation

To install NitroHypr and its dependencies, clone the repository and run the installation script:

```bash
git clone https://github.com/Nitro-OS/NitroHypr.git
cd NitroHypr
chmod +x install.sh uninstall.sh update.sh
./install.sh
```

During installation:
1. Select your preferred package helper (`yay`, `paru`, or `pacman`).
2. Choose which packages to install.
3. Choose whether to install the custom NitroVim configuration.
4. Log out of your current session, select **Hyprland** (or **Hyprland (UWSM)**) in your display manager (GDM, SDDM, etc.), and log in.

---

## Updating

Keep your configuration files and package list updated with the latest releases:

```bash
./update.sh
```
This pulls the latest commits, updates files in `~/.config`, and optionally updates your system packages.

---

## Uninstallation

If you wish to uninstall NitroHypr and revert changes:

```bash
./uninstall.sh
```

Our uninstall script is robust and ensures a complete cleanup:
- **Display Manager Cleanup**: Safely resets remembered/default session configurations in GDM/AccountsService, SDDM, LightDM, and `~/.dmrc`, preventing any login issues or black screens.
- **Safe Package Removal**: Filters out and removes only the packages that are currently installed on the system (categorized into core Hyprland and general utility packages) to prevent uninstallation failure or broken system tools.
- **Orphan File Removal**: Automatically purges leftover `.desktop` session files from the system.
- **Backup Restoration**: Offers to restore any previous backup case-insensitive searchconfigurations created during installation.
