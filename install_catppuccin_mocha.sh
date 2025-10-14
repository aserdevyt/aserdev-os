#!/usr/bin/env bash
# 💅 aserdev-OS Catppuccin Mocha SDDM Installer
# License: MIT
# Repo: https://github.com/catppuccin/sddm

set -euo pipefail

# colors
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RESET="\033[0m"

TMP_DIR="/tmp/catppuccin-sddm"
THEME_DIR="/usr/share/sddm/themes"
THEME_FLAVOR="catppuccin-mocha-mauve"

echo -e "${CYAN}💅 Installing Catppuccin Mocha (Mauve) for SDDM...${RESET}"

# must be root
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}⚠️  Run this as root bro 💀${RESET}"
  exit 1
fi

# check git
if ! command -v git &>/dev/null; then
  echo -e "${YELLOW}Installing git...${RESET}"
  if command -v pacman &>/dev/null; then
    pacman -Sy --noconfirm git
  elif command -v apt &>/dev/null; then
    apt update && apt install -y git
  else
    echo -e "${RED}No supported package manager found 💀${RESET}"
    exit 1
  fi
fi

# grab the repo
echo -e "${CYAN}>>> Cloning Catppuccin SDDM repo...${RESET}"
rm -rf "$TMP_DIR"
git clone --depth=1 https://github.com/catppuccin/sddm.git "$TMP_DIR"

# copy the mocha flavor
echo -e "${CYAN}>>> Installing Catppuccin Mocha (Mauve) theme...${RESET}"
mkdir -p "$THEME_DIR"
cp -r "$TMP_DIR/$THEME_FLAVOR" "$THEME_DIR/"

# apply it
echo -e "${CYAN}>>> Setting theme in /etc/sddm.conf.d/aserdev-theme.conf${RESET}"
mkdir -p /etc/sddm.conf.d
cat <<EOF >/etc/sddm.conf.d/aserdev-theme.conf
[Theme]
Current=$THEME_FLAVOR
EOF

# cleanup
rm -rf "$TMP_DIR"

echo -e "${GREEN}✅ Catppuccin Mocha (Mauve) SDDM theme installed successfully!${RESET}"
echo -e "${YELLOW}💫 Reboot to flex your new login screen.${RESET}"
