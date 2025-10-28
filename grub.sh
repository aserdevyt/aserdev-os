#!/usr/bin/env bash
# 💀 aserdev-OS GRUB Chaos Script v2 — now with safety checks 😎

set -euo pipefail

# ANSI colors
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
MAGENTA="\033[1;35m"
CYAN="\033[1;36m"
RESET="\033[0m"

GRUB_FILE="/etc/default/grub"
GRUB_CFG="/boot/grub/grub.cfg"

# Detect grub.cfg path
if [[ -d /boot/grub2 ]]; then
  GRUB_CFG="/boot/grub2/grub.cfg"
fi

clear
echo -e "${RED}"

# FIGLET check
if ! command -v figlet &>/dev/null; then
  echo -e "${YELLOW}Installing figlet for style points...${RESET}"
  pacman -Sy --noconfirm figlet >/dev/null 2>&1 || true
fi

figlet -f slant "aserdev-OS"
echo -e "${RESET}"

echo -e "${CYAN}>>> Checking permissions...${RESET}"
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}⚠️  Run me as root, bro 💀${RESET}"
  exit 1
fi

echo -e "${YELLOW}>>> Backing up ${GRUB_FILE}...${RESET}"
cp -f "$GRUB_FILE" "${GRUB_FILE}.bak"
sleep 0.3

echo -e "${BLUE}>>> Patching kernel loglevel...${RESET}"
if grep -q "loglevel=" "$GRUB_FILE"; then
  sed -i 's/loglevel=[0-9]/loglevel=7/g' "$GRUB_FILE"
else
  sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=7 /' "$GRUB_FILE"
fi
sleep 0.2

echo -e "${MAGENTA}>>> Removing 'quiet' param...${RESET}"
sed -i 's/\bquiet\b//g' "$GRUB_FILE"
sleep 0.2

echo -e "${GREEN}>>> Regenerating GRUB config...${RESET}"
if command -v grub-mkconfig &>/dev/null; then
  grub-mkconfig -o "$GRUB_CFG" >/tmp/grub_update.log 2>&1
  echo -e "${CYAN}✔️  grub.cfg updated${RESET}"
else
  echo -e "${RED}❌ grub-mkconfig not found, fix ur grub 💀${RESET}"
  exit 1
fi

sleep 0.3
echo -e "${YELLOW}>>> Renaming Arch Linux entries → aserdev-OS${RESET}"
if grep -q "Arch Linux" "$GRUB_CFG"; then
  sed -i 's/Arch Linux.*/aserdev-OS/g' "$GRUB_CFG"
  echo -e "${GREEN}🔥 Done!${RESET}"
else
  echo -e "${RED}🫠 No 'Arch Linux' entry found, bruh${RESET}"
fi

sleep 0.3
echo -e "${BLUE}>>> Showing preview...${RESET}"
grep -i "menuentry" "$GRUB_CFG" | head -n 3
sleep 0.3

echo -e "${GREEN}✔️  GRUB chaos complete. Enjoy the noise 😎${RESET}"

