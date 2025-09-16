#!/usr/bin/env bash
# =============================================
# AserDev Repo + Chaotic-AUR Installer 💀
# =============================================
set -euo pipefail

msg()  { echo -e "\e[36m[*]\e[0m $1"; }
ok()   { echo -e "\e[32m[✔]\e[0m $1"; }
warn() { echo -e "\e[33m[!]\e[0m $1"; }

# -------------------------
# Ensure we're not root
# -------------------------
if [ "$EUID" -eq 0 ]; then
    warn "Do NOT run as root. This script will use sudo where needed."
fi

# -------------------------
# Chaotic-AUR setup
# -------------------------
if ! grep -q "chaotic-aur" /etc/pacman.conf; then
    msg "Adding Chaotic-AUR..."
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key 3056513887B78AEB
    sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
    sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    # Append repo to pacman.conf if not already there
    if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
        echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf >/dev/null
    fi
    ok "Chaotic-AUR added!"
else
    ok "Chaotic-AUR already configured."
fi

# -------------------------
# AserDev repo setup
# -------------------------
if ! grep -q "aserdev" /etc/pacman.conf; then
    msg "Adding AserDev repo..."
    # Make sure directory exists
    sudo mkdir -p /etc/pacman.d/aserdev
    # Add repo entry to pacman.conf
    echo -e "\n[aserdev]\nSigLevel = Optional TrustAll\nServer = https://cdn.jsdelivr.net/gh/aserdevyt/aserdev-repo/\$arch" | sudo tee -a /etc/pacman.conf >/dev/null
    ok "AserDev repo added!"
else
    ok "AserDev repo already configured."
fi

# -------------------------
# Update databases
# -------------------------
msg "Syncing pacman databases..."
sudo pacman -Syy --noconfirm
ok "Databases synced! ✅"

# -------------------------
# Done
# -------------------------
msg "All repos installed and ready to use!"
