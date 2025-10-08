#!/usr/bin/env bash
set -euo pipefail

# install deps
sudo pacman -Syu --noconfirm --needed base-devel git base figlet curl wget

clear
figlet "CONFIRMATION"

# colors
red="\e[31m"
green="\e[32m"
yellow="\e[33m"
blue="\e[34m"
magenta="\e[35m"
cyan="\e[36m"
white="\e[37m"
reset="\e[0m"

echo -e "${red}wsp${reset} this ${green}script${reset} will install ${blue}aserdev-os${reset}."
echo -e "It ${yellow}overrides${reset} your install of ${cyan}Arch Linux${reset} with ${magenta}aserdev-os${reset}."
echo -e "Do you want to continue? (y/N)"
read -r answer

# make N default
answer=${answer:-n}

if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
    echo -e "${red}Exiting...${reset}"
    exit 1
fi

echo -e "${green}Continuing...${reset}"
sleep 1
clear
figlet "INSTALLATION"

# run your main install script
bash <(curl -fsSL https://raw.githubusercontent.com/aserdevyt/aserdev-repo/refs/heads/main/install.sh)

clear
figlet "OS SETUP"

# Replace /etc/os-release
REMOTE_URL="https://raw.githubusercontent.com/aserdevyt/aserdev-os/refs/heads/main/os-release"
TARGET="/etc/os-release"
BACKUP="/etc/os-release.bak.$(date +%s)"

echo -e "${yellow}Backing up current os-release...${reset}"
if [[ -f "$TARGET" ]]; then
    sudo cp "$TARGET" "$BACKUP"
    echo -e "${cyan}Backup created at${reset} ${white}$BACKUP${reset}"
fi

echo -e "${yellow}Downloading new os-release...${reset}"
if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$REMOTE_URL" -o /tmp/os-release.new
elif command -v wget >/dev/null 2>&1; then
    wget -qO /tmp/os-release.new "$REMOTE_URL"
else
    echo -e "${red}curl/wget not found, can't download file.${reset}"
    exit 1
fi

if [[ ! -s /tmp/os-release.new ]]; then
    echo -e "${red}Download failed or empty file.${reset}"
    exit 1
fi

sudo cp /tmp/os-release.new "$TARGET"
sudo chmod 644 "$TARGET"
sudo chown root:root "$TARGET"

echo -e "${green}Successfully replaced /etc/os-release with aserdev-os info.${reset}"
sleep 1

clear
figlet "DOTFILES"

# clone and install dotfiles
if [[ -d "$HOME/aserdev-dotfiles" ]]; then
    echo -e "${yellow}Existing aserdev-dotfiles found, removing...${reset}"
    rm -rf "$HOME/aserdev-dotfiles"
fi

echo -e "${cyan}Cloning aserdev-dotfiles...${reset}"
git clone --depth=1 https://github.com/aserdevyt/aserdev-dotfiles.git "$HOME/aserdev-dotfiles"

cd "$HOME/aserdev-dotfiles"

if [[ -x "./install" ]]; then
    echo -e "${green}Running dotfiles installer (silent)...${reset}"
    ./install --silent || echo -e "${red}Dotfiles install failed 💀${reset}"
else
    echo -e "${red}No install script found in dotfiles repo 💀${reset}"
fi

clear
figlet "DONE"
echo -e "${blue}Installation complete!${reset} ${magenta}Welcome to aserdev-os 🚀${reset}"
