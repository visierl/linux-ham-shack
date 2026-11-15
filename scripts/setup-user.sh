#!/usr/bin/env bash
set -euo pipefail

TEMPLATE_DIR="/usr/share/linux-ham-shack/configs"
BACKUP_DIR="$HOME/.config/linux-ham-shack-backup-$(date +%Y%m%d-%H%M%S)"
QUISK_CONF_PATH="\$HOME/.config/quisk/quisk_conf.py"
SELECTED_RADIO=""

# Parse optional CLI arguments (e.g., quisk-station-init --radio hl2)
while [[ $# -gt 0 ]]; do
    case "$1" in
        --radio)
            SELECTED_RADIO="${2:-}"
            shift 2
            ;;
        -h|--help)
            echo "Usage: quisk-station-init [--radio <profile_name>]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [[ $EUID -eq 0 ]]; then
    echo "Error: Run quisk-station-init as your normal radio operator user, not root."
    exit 1
fi

echo "==> Setting up Quisk SDR Station for user: $USER"

# 1. Discover available radio profiles in $TEMPLATE_DIR/quisk/radios/
RADIOS_DIR="$TEMPLATE_DIR/quisk/radios"
mapfile -t AVAILABLE_RADIOS < <(find "$RADIOS_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort)

if [[ ${#AVAILABLE_RADIOS[@]} -eq 0 ]]; then
    echo "Error: No radio profiles found in $RADIOS_DIR"
    exit 1
fi

if [[ -n "$SELECTED_RADIO" ]]; then
    if [[ ! -d "$RADIOS_DIR/$SELECTED_RADIO" ]]; then
        echo "Error: Radio profile '$SELECTED_RADIO' not found."
        echo "Available profiles: ${AVAILABLE_RADIOS[*]}"
        exit 1
    fi
elif [[ ${#AVAILABLE_RADIOS[@]} -eq 1 ]]; then
    SELECTED_RADIO="${AVAILABLE_RADIOS[0]}"
    echo "==> Selected default radio profile: $SELECTED_RADIO"
else
    echo ""
    echo "Available Radio Profiles:"
    for i in "${!AVAILABLE_RADIOS[@]}"; do
        r="${AVAILABLE_RADIOS[$i]}"
        desc=""
        if [[ -f "$RADIOS_DIR/$r/description.txt" ]]; then
            desc=" - $(head -n 1 "$RADIOS_DIR/$r/description.txt")"
        fi
        printf "  [%d] %s%s\n" "$((i + 1))" "$r" "$desc"
    done
    echo ""
    read -rp "Select radio profile [1-${#AVAILABLE_RADIOS[@]}] (default: 1): " choice
    choice="${choice:-1}"
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#AVAILABLE_RADIOS[@]} )); then
        echo "Invalid selection."
        exit 1
    fi
    SELECTED_RADIO="${AVAILABLE_RADIOS[$((choice - 1))]}"
fi

echo "==> Configuring station for radio: $SELECTED_RADIO"

# 2. Ensure user is in dialout and audio groups for hardware/CAT access
NEED_RELOGIN=0
for grp in dialout audio; do
    if getent group "$grp" >/dev/null && ! id -nG "$USER" | grep -qw "$grp"; then
        echo "==> Adding $USER to '$grp' group (requires sudo)..."
        sudo usermod -aG "$grp" "$USER"
        NEED_RELOGIN=1
    fi
done

# 3. Helper function to safely back up and copy files/directories
deploy_config() {
    local src="$1"
    local dest="$2"

    if [[ -e "$dest" ]]; then
        mkdir -p "$BACKUP_DIR"
        echo "    Backing up existing $dest -> $BACKUP_DIR/"
        cp -a "$dest" "$BACKUP_DIR/"
    fi

    mkdir -p "$(dirname "$dest")"
    cp -a "$src" "$dest"
    echo "    Installed $dest"
}

echo "==> Deploying configuration templates..."
deploy_config "$TEMPLATE_DIR/pipewire/pipewire.conf.d" "$HOME/.config/pipewire/pipewire.conf.d"
deploy_config "$TEMPLATE_DIR/pipewire/jack.conf.d" "$HOME/.config/pipewire/jack.conf.d"
deploy_config "$TEMPLATE_DIR/carla/station-rack.carxp" "$HOME/.config/carla/station-rack.carxp"
deploy_config "$TEMPLATE_DIR/carla/Carla2.conf" "$HOME/.config/rncbc.org/Carla2.conf"
# Deploy common Quisk config, then overlay the chosen radio profile
if [[ -d "$HOME/.config/quisk" ]]; then
    mkdir -p "$BACKUP_DIR"
    echo "    Backing up existing $HOME/.config/quisk -> $BACKUP_DIR/"
    cp -a "$HOME/.config/quisk" "$BACKUP_DIR/"
fi
mkdir -p "$HOME/.config/quisk"
cp -f "$TEMPLATE_DIR/quisk/common/quisk_conf.py" "$HOME/.config/quisk/quisk_conf.py"
cp -f "$RADIOS_DIR/$SELECTED_RADIO/quisk_settings.json" "$HOME/.config/quisk/quisk_settings.json"
# Optional: allow a radio profile to supply its own quisk_conf.py override if present
if [[ -f "$RADIOS_DIR/$SELECTED_RADIO/quisk_conf.py" ]]; then
    cp -f "$RADIOS_DIR/$SELECTED_RADIO/quisk_conf.py" "$HOME/.config/quisk/quisk_conf.py"
fi
echo "    Installed Quisk profile ($SELECTED_RADIO) -> $HOME/.config/quisk/"

# 4. Install XDG Autostart entry for Carla (minimized to system tray on login)
mkdir -p "$HOME/.config/autostart"
cp -f "$TEMPLATE_DIR/autostart/carla-station.desktop" "$HOME/.config/autostart/"
echo "    Installed autostart entry (~/.config/autostart/carla-station.desktop)"

# 5. Install desktop application launcher for Quisk
mkdir -p "$HOME/.local/share/applications"
cp -f "$TEMPLATE_DIR/desktop/quisk-station.desktop" "$HOME/.local/share/applications/"
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications" || true
fi
echo "    Installed desktop launcher (~/.local/share/applications/quisk-station.desktop)"

# 6. Add 'quisk' shell alias to Bash, Zsh, and Fish profiles (idempotent)
add_posix_alias() {
    local rc_file="$1"
    local alias_line="alias quisk='quisk -c \"$QUISK_CONF_PATH\"'"

    if [[ "$rc_file" == "$HOME/.bashrc" || -f "$rc_file" || -x "$(command -v zsh)" ]]; then
        touch "$rc_file"
        if ! grep -Fq "quisk -c" "$rc_file"; then
            {
                echo ""
                echo "# Quisk SDR Station config path"
                echo "$alias_line"
            } >> "$rc_file"
            echo "    Added quisk alias to $rc_file"
        else
            echo "    Quisk alias already present in $rc_file"
        fi
    fi
}

echo "==> Configuring shell aliases..."
add_posix_alias "$HOME/.bashrc"

if command -v zsh >/dev/null 2>&1 || [[ -f "$HOME/.zshrc" ]]; then
    add_posix_alias "$HOME/.zshrc"
fi

if command -v fish >/dev/null 2>&1 || [[ -d "$HOME/.config/fish" ]]; then
    FISH_CONF="$HOME/.config/fish/config.fish"
    mkdir -p "$(dirname "$FISH_CONF")"
    touch "$FISH_CONF"
    if ! grep -Fq "quisk -c" "$FISH_CONF"; then
        {
            echo ""
            echo "# Quisk SDR Station config path"
            echo "alias quisk 'quisk -c \"\$HOME/.config/quisk/quisk_conf.py\"'"
        } >> "$FISH_CONF"
        echo "    Added quisk alias to $FISH_CONF"
    fi
fi

# 7. Restart PipeWire so virtual sinks appear immediately
echo "==> Reloading PipeWire services..."
systemctl --user restart pipewire.service pipewire-pulse.service wireplumber.service || true

echo ""
echo "==> Station configuration complete for '$SELECTED_RADIO'!"
echo "    - Run 'source ~/.bashrc' (or open a new terminal) to activate the 'quisk' alias."
echo "    - Carla will launch into your system tray automatically on next login"
echo "      (or start it now with: pw-jack carla ~/.config/carla/station-rack.carxp &)."
if [[ $NEED_RELOGIN -eq 1 ]]; then
    echo "    - IMPORTANT: Log out and back in for new 'dialout'/'audio' group permissions to take effect."
fi
