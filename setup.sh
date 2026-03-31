#!/usr/bin/env bash
# ============================================================================
# Hyprland Rice Install Script — Arch Linux
# Catppuccin Mocha | Fish + Starship | uwsm + greetd
# ============================================================================
set -euo pipefail

# --- Colors -----------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()      { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()     { echo -e "${RED}[ERROR]${NC} $*"; }
section() { echo -e "\n${CYAN}${BOLD}==> $*${NC}"; }

# --- Pre-flight checks ------------------------------------------------------
section "Pre-flight checks"

if [[ $EUID -eq 0 ]]; then
    err "Do not run this script as root. Run as your normal user."
    exit 1
fi

if ! command -v pacman &>/dev/null; then
    err "pacman not found. This script is for Arch Linux only."
    exit 1
fi

info "Testing sudo access..."
if ! sudo -v; then
    err "sudo authentication failed."
    exit 1
fi
ok "sudo access confirmed"

info "Checking internet connectivity..."
if ! ping -c 1 -W 3 archlinux.org &>/dev/null; then
    err "No internet connection. Please connect and try again."
    exit 1
fi
ok "Internet connection available"

# Keep sudo alive in background
(while true; do sudo -n true; sleep 50; done) &
SUDO_PID=$!
trap "kill $SUDO_PID 2>/dev/null; exit" EXIT INT TERM

# --- AUR helper -------------------------------------------------------------
section "AUR helper"

AUR_HELPER=""
if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
    ok "Found paru"
elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
    ok "Found yay"
else
    info "No AUR helper found. Installing yay..."
    sudo pacman -S --needed --noconfirm git base-devel
    TMPDIR=$(mktemp -d)
    git clone https://aur.archlinux.org/yay-bin.git "$TMPDIR/yay-bin"
    (cd "$TMPDIR/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$TMPDIR"
    AUR_HELPER="yay"
    ok "yay installed"
fi

# --- Package lists -----------------------------------------------------------
PACMAN_PKGS=(
    # Hyprland core
    hyprland
    hyprlock
    hypridle
    uwsm

    # Display manager
    greetd
    greetd-tuigreet

    # Desktop utilities
    waybar
    kitty
    rofi-wayland
    thunar
    grim
    slurp
    wl-clipboard
    brightnessctl
    playerctl
    network-manager-applet
    blueman
    udiskie

    # Polkit & portals
    hyprpolkitagent
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk

    # Night light
    hyprsunset

    # Qt theming
    qt5ct
    nwg-look

    # Shell & CLI tools
    fish
    starship
    eza
    bat
    fd
    ripgrep
    fzf
    zoxide
    fastfetch
    btop

    # Fonts
    ttf-jetbrains-mono-nerd

    # Audio
    pipewire
    wireplumber

    # Icons
    papirus-icon-theme

    # Misc
    wf-recorder
)

AUR_PKGS=(
    swww
    swaync
    wlogout
    catppuccin-gtk-theme-mocha
    catppuccin-cursors-mocha
    cliphist
)

# --- Install official packages -----------------------------------------------
section "Installing official packages (pacman)"

install_pacman_batch() {
    if sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"; then
        ok "All official packages installed"
        return 0
    else
        return 1
    fi
}

install_pacman_individual() {
    warn "Batch install failed. Falling back to one-by-one..."
    local failed=()
    for pkg in "${PACMAN_PKGS[@]}"; do
        if ! sudo pacman -S --needed --noconfirm "$pkg" &>/dev/null; then
            failed+=("$pkg")
            warn "Failed to install: $pkg"
        fi
    done
    if [[ ${#failed[@]} -gt 0 ]]; then
        warn "Failed packages: ${failed[*]}"
    else
        ok "All official packages installed (one-by-one)"
    fi
}

install_pacman_batch || install_pacman_individual

# --- Install AUR packages ----------------------------------------------------
section "Installing AUR packages ($AUR_HELPER)"

install_aur_batch() {
    if $AUR_HELPER -S --needed --noconfirm "${AUR_PKGS[@]}"; then
        ok "All AUR packages installed"
        return 0
    else
        return 1
    fi
}

install_aur_individual() {
    warn "Batch AUR install failed. Falling back to one-by-one..."
    local failed=()
    for pkg in "${AUR_PKGS[@]}"; do
        if ! $AUR_HELPER -S --needed --noconfirm "$pkg" &>/dev/null; then
            failed+=("$pkg")
            warn "Failed to install AUR: $pkg"
        fi
    done
    if [[ ${#failed[@]} -gt 0 ]]; then
        warn "Failed AUR packages: ${failed[*]}"
    else
        ok "All AUR packages installed (one-by-one)"
    fi
}

install_aur_batch || install_aur_individual

# --- Display manager setup ---------------------------------------------------
section "Configuring greetd + tuigreet"

# Disable any existing display manager
for dm in sddm gdm lightdm ly; do
    if systemctl is-enabled "${dm}.service" &>/dev/null; then
        warn "Disabling existing display manager: $dm"
        sudo systemctl disable "${dm}.service" 2>/dev/null || true
    fi
done

# Enable greetd
sudo systemctl enable greetd.service
ok "greetd service enabled"

# Configure greetd for tuigreet + uwsm
GREETD_CONF="/etc/greetd/config.toml"
if [[ -f "$GREETD_CONF" ]]; then
    BACKUP="/etc/greetd/config.toml.bak.$(date +%Y%m%d%H%M%S)"
    sudo cp "$GREETD_CONF" "$BACKUP"
    info "Backed up existing greetd config to $BACKUP"
fi
info "Writing $GREETD_CONF"
sudo tee "$GREETD_CONF" > /dev/null << 'GREETDEOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --remember-session --asterisks --sessions /usr/share/wayland-sessions"
user = "greeter"
GREETDEOF
ok "greetd configured with tuigreet"

# Ensure current user is in the video group (for tuigreet)
if ! groups "$USER" | grep -q '\bvideo\b'; then
    sudo usermod -aG video "$USER"
    info "Added $USER to video group"
fi

# --- Change default shell to Fish ---------------------------------------------
section "Setting default shell to Fish"

if [[ "$SHELL" != "/usr/bin/fish" ]]; then
    chsh -s /usr/bin/fish
    ok "Default shell changed to fish (takes effect on next login)"
else
    ok "Fish is already the default shell"
fi

# --- Apply GTK/icon/cursor theme via gsettings --------------------------------
section "Applying GTK theme settings"

if command -v gsettings &>/dev/null; then
    # Detect actual installed Catppuccin theme name
    GTK_THEME_NAME=""
    if [[ -d /usr/share/themes/catppuccin-mocha-mauve-standard+default ]]; then
        GTK_THEME_NAME="catppuccin-mocha-mauve-standard+default"
    else
        # Fallback: find any installed catppuccin-mocha theme
        GTK_THEME_NAME=$(ls -d /usr/share/themes/catppuccin-mocha-mauve* 2>/dev/null | head -1 | xargs basename 2>/dev/null || true)
    fi

    if [[ -n "$GTK_THEME_NAME" ]]; then
        gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME_NAME"
        ok "GTK theme set to $GTK_THEME_NAME"
    else
        warn "No Catppuccin GTK theme found in /usr/share/themes/"
    fi

    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
    gsettings set org.gnome.desktop.interface font-name 'JetBrainsMono Nerd Font 11'
    gsettings set org.gnome.desktop.interface cursor-theme 'catppuccin-mocha-mauve-cursors'
    gsettings set org.gnome.desktop.interface cursor-size 24
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    ok "gsettings applied (icons, font, cursor, dark mode)"
else
    warn "gsettings not found — run nwg-look manually to apply GTK theme"
fi

# --- uwsm env GTK_THEME -------------------------------------------------------
UWSM_ENV="$HOME/.config/uwsm/env"
if [[ -f "$UWSM_ENV" ]]; then
    if ! grep -q "GTK_THEME" "$UWSM_ENV"; then
        if [[ -n "${GTK_THEME_NAME:-}" ]]; then
            echo "export GTK_THEME=$GTK_THEME_NAME" >> "$UWSM_ENV"
            ok "Added GTK_THEME to uwsm env"
        fi
    else
        ok "GTK_THEME already set in uwsm env"
    fi
fi

# --- Post-install verification ------------------------------------------------
section "Post-install verification"

# Rebuild font cache first
info "Rebuilding font cache..."
fc-cache -f 2>/dev/null
ok "Font cache rebuilt"

MISSING_BINS=()
# Note: swww package installs as awww/awww-daemon on Arch
for bin in hyprland hyprlock hypridle hyprsunset waybar kitty rofi fish starship eza bat fd rg fzf zoxide fastfetch btop brightnessctl playerctl grim slurp wl-copy awww cliphist swaync-client wlogout uwsm tuigreet; do
    if command -v "$bin" &>/dev/null; then
        ok "Found: $bin"
    else
        MISSING_BINS+=("$bin")
        warn "Missing: $bin"
    fi
done

# Check font
if fc-list : family | grep -qi "JetBrainsMono Nerd Font"; then
    ok "JetBrainsMono Nerd Font installed"
else
    warn "JetBrainsMono Nerd Font not found"
fi

# Check GTK theme
if [[ -d /usr/share/themes/catppuccin-mocha-mauve-standard+default ]] || \
   ls /usr/share/themes/catppuccin-mocha-mauve* &>/dev/null 2>&1; then
    ok "Catppuccin GTK theme found"
else
    warn "Catppuccin GTK theme not found in /usr/share/themes/"
fi

# Check cursor theme
if ls -d /usr/share/icons/catppuccin-mocha-mauve-cursors &>/dev/null 2>&1; then
    ok "Catppuccin cursor theme found"
else
    warn "Catppuccin cursor theme not found in /usr/share/icons/"
fi

# Check icon theme
if [[ -d /usr/share/icons/Papirus-Dark ]]; then
    ok "Papirus-Dark icon theme found"
else
    warn "Papirus-Dark icon theme not found"
fi

# --- Summary ------------------------------------------------------------------
section "Installation Summary"

echo -e "${GREEN}${BOLD}Installation complete!${NC}\n"

if [[ ${#MISSING_BINS[@]} -gt 0 ]]; then
    warn "Missing binaries: ${MISSING_BINS[*]}"
    echo -e "  You may need to install these manually.\n"
fi

echo -e "${BOLD}What was set up:${NC}"
echo "  - Hyprland + hyprlock + hypridle + hyprsunset + uwsm"
echo "  - greetd + tuigreet (display manager)"
echo "  - Fish shell + Starship prompt + CLI tools"
echo "  - Catppuccin Mocha Mauve — GTK theme, cursors, Papirus-Dark icons"
echo "  - JetBrainsMono Nerd Font"
echo "  - Waybar, Kitty, Rofi, Thunar, swaync, wlogout"
echo "  - swww (awww) wallpaper daemon + clipboard history (cliphist)"
echo "  - PipeWire + WirePlumber audio stack"
echo "  - Blueman, udiskie, nm-applet, hyprpolkitagent"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo "  1. Add wallpapers to ~/Pictures/wallpapers/catppuccin-mocha/"
echo "  2. Run 'qt5ct' to configure Qt theme if needed"
echo "  3. Reboot to start greetd + Hyprland via uwsm"
echo ""
echo -e "${YELLOW}NOTE:${NC} Log out and back in for the Fish shell change to take effect."
