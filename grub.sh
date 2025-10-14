#!/usr/bin/env bash
# 💀 aserdev-OS GRUB Chaos Script — with FIGLET + ANSI colors 😎

set -e

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

clear
echo -e "${RED}"
figlet -f slant "aserdev-OS"
echo -e "${RESET}"

echo -e "${CYAN}>>> Checking permissions...${RESET}"
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}⚠️  Run me as root, bro 💀${RESET}"
  exit 1
fi

echo -e "${YELLOW}>>> Backing up ${GRUB_FILE}...${RESET}"
cp "$GRUB_FILE" "${GRUB_FILE}.bak"
sleep 0.5

echo -e "${BLUE}>>> Patching kernel loglevel...${RESET}"
sed -i 's/loglevel=3/loglevel=7/g' "$GRUB_FILE"
sleep 0.3

echo -e "${MAGENTA}>>> Removing 'quiet' param...${RESET}"
sed -i 's/\bquiet\b//g' "$GRUB_FILE"
sleep 0.3

echo -e "${GREEN}>>> Regenerating GRUB config...${RESET}"
if command -v grub-mkconfig &>/dev/null; then
  grub-mkconfig -o "$GRUB_CFG" >/tmp/grub_update.log 2>&1
  echo -e "${CYAN}✔️  grub.cfg updated${RESET}"
else
  echo -e "${RED}❌ grub-mkconfig not found, fix ur grub 💀${RESET}"
  exit 1
fi

sleep 0.5
echo -e "${YELLOW}>>> Renaming Arch Linux entry → aserdev-OS${RESET}"
if grep -q "Arch Linux" "$GRUB_CFG"; then
  sed -i 's/Arch Linux/aserdev-OS/g' "$GRUB_CFG"
  echo -e "${GREEN}🔥 Done!${RESET}"
else
  echo -e "${RED}🫠 No 'Arch Linux' entry found, bruh${RESET}"
fi

sleep 0.6
echo -e "${MAGENTA}"
figlet -f slant "Reboot Ready"
echo -e "${RESET}${BLUE}>>> Restart and witness chaos unfold 💀${RESET}"
