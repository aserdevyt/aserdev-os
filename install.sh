#!/usr/bin/env bash
# aserdev-OS safer installer — remade
# Keepin' the vibes but not nuking people's installs 💀
set -euo pipefail

# ---------- appearance ----------
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
MAGENTA="\033[1;35m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"
RESET="\033[0m"

figlet_exists() { command -v figlet &>/dev/null; }

# If figlet missing, fallback to plain echo banner
banner() {
  if figlet_exists; then
    figlet -f slant "$1"
  else
    echo -e "${MAGENTA}===== $1 =====${RESET}"
  fi
}

# ---------- env helpers ----------
# Determine whether to prefix commands with sudo
if [[ $EUID -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

# Detect original user/home when run with sudo
if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
  INVOKER="${SUDO_USER}"
  INVOKER_HOME="$(getent passwd "$INVOKER" | cut -d: -f6)"
else
  INVOKER="$(id -un)"
  INVOKER_HOME="${HOME}"
fi

# Tmp paths
TMP="/tmp/aserdev-installer.$$"
mkdir -p "$TMP"

# ---------- confirmation ----------
clear
banner "CONFIRM"

echo -e "${RED}wsp${RESET} this ${GREEN}script${RESET} will install ${BLUE}aserdev-os${RESET}."
echo -e "It ${YELLOW}overrides${RESET} some parts of your Arch install (os-release, grub, dotfiles, theme)."
echo -e "Do you want to continue? (y/N)"
read -r answer
answer=${answer:-n}

if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
  echo -e "${RED}Exiting...${RESET}"
  rm -rf "$TMP"
  exit 1
fi

echo -e "${GREEN}Continuing...${RESET}"
sleep 1

# ---------- install dependencies (after confirmation) ----------
banner "INSTALL"

echo -e "${CYAN}Checking for package manager & installing deps...${RESET}"

install_packages() {
  # params: package names...
  if command -v pacman &>/dev/null; then
    $SUDO pacman -Syu --noconfirm --needed "$@"
  elif command -v apt &>/dev/null; then
    $SUDO apt update
    $SUDO apt install -y "$@"
  else
    echo -e "${YELLOW}No supported package manager detected (pacman/apt). Please install git/figlet/curl/wget/zsh manually.${RESET}"
  fi
}

# Install core tools plus zsh, which is needed for shell setup
install_packages git figlet curl wget zsh

# ---------- run main install script (download-first) ----------
MAIN_INSTALL_URL="https://raw.githubusercontent.com/aserdevyt/aserdev-repo/main/install.sh"
MAIN_INSTALL_LOCAL="$TMP/install.sh"

echo -e "${CYAN}Downloading main install script...${RESET}"
curl -fsSL "$MAIN_INSTALL_URL" -o "$MAIN_INSTALL_LOCAL"
if [[ ! -s "$MAIN_INSTALL_LOCAL" ]]; then
  echo -e "${RED}Failed to download main installer.${RESET}"
else
  echo -e "${CYAN}Running main installer...${RESET}"
  # Run as root to allow privileged operations inside the installer
  $SUDO bash "$MAIN_INSTALL_LOCAL" || echo -e "${YELLOW}Main installer failed (continuing with the rest).${RESET}"
fi

# ---------- grub script (download-first, run as root) ----------
GRUB_URL="https://raw.githubusercontent.com/aserdevyt/aserdev-os/main/grub.sh"
GRUB_LOCAL="$TMP/grub.sh"

echo -e "${CYAN}Downloading grub script...${RESET}"
curl -fsSL "$GRUB_URL" -o "$GRUB_LOCAL"
if [[ -s "$GRUB_LOCAL" ]]; then
  echo -e "${CYAN}Executing grub script as root...${RESET}"
  $SUDO bash "$GRUB_LOCAL" || echo -e "${RED}grub script failed — check /tmp for logs${RESET}"
else
  echo -e "${YELLOW}Could not download grub script, skipping grub changes.${RESET}"
fi

# ---------- replace /etc/os-release (with backup) ----------
OS_RELEASE_URL="https://raw.githubusercontent.com/aserdevyt/aserdev-os/main/os-release"
OS_RELEASE_TMP="$TMP/os-release.new"
OS_RELEASE_TARGET="/etc/os-release"
OS_RELEASE_BACKUP="/etc/os-release.bak.$(date +%s)"

echo -e "${CYAN}Backing up current /etc/os-release (if exists)...${RESET}"
if [[ -f "$OS_RELEASE_TARGET" ]]; then
  $SUDO cp "$OS_RELEASE_TARGET" "$OS_RELEASE_BACKUP"
  echo -e "${WHITE}Backup created at${RESET} ${OS_RELEASE_BACKUP}"
fi

echo -e "${CYAN}Downloading new os-release...${RESET}"
curl -fsSL "$OS_RELEASE_URL" -o "$OS_RELEASE_TMP"

if [[ -s "$OS_RELEASE_TMP" ]]; then
  $SUDO cp "$OS_RELEASE_TMP" "$OS_RELEASE_TARGET"
  $SUDO chmod 644 "$OS_RELEASE_TARGET"
  $SUDO chown root:root "$OS_RELEASE_TARGET"
  echo -e "${GREEN}Replaced /etc/os-release${RESET}"
else
  echo -e "${YELLOW}Failed to fetch new os-release; skipping.${RESET}"
fi

# ---------- Package-based Skeleton and Shell Setup (Replaces Dotfiles) ----------
banner "SETUP"

# 1. Install skeleton and all-in-one packages
echo -e "${CYAN}Installing aserdev-os-skel and aserdev-os-all packages...${RESET}"
install_packages aserdev-os-skel aserdev-os-all

# 2. Copy skeleton files to the current user's home
echo -e "${CYAN}Copying skeleton files from /etc/skel to ${INVOKER_HOME} for user ${INVOKER}...${RESET}"
if [[ -d "/etc/skel" ]]; then
    # Copy contents, including hidden files, and preserve ownership (which is currently root/root)
    $SUDO cp -R /etc/skel/. "$INVOKER_HOME" || echo -e "${YELLOW}Warning: Failed to copy /etc/skel contents.${RESET}"
    # Ensure all copied files are owned by the invoking user
    $SUDO chown -R "$INVOKER":"$(id -g -n "$INVOKER")" "$INVOKER_HOME" || echo -e "${YELLOW}Warning: Failed to fix ownership in home directory.${RESET}"
    echo -e "${GREEN}Skeleton files applied.${RESET}"
else
    echo -e "${RED}Error: /etc/skel directory not found after package install. Skipping skeleton copy.${RESET}"
fi


# 3. Change current user's shell to zsh
echo -e "${CYAN}Setting current user (${INVOKER}) shell to /bin/zsh...${RESET}"
if command -v chsh &>/dev/null; then
    # chsh requires the full path to the shell
    $SUDO chsh -s /bin/zsh "$INVOKER" || echo -e "${YELLOW}Warning: Failed to change ${INVOKER}'s shell using chsh. Check if /bin/zsh exists.${RESET}"
else
    echo -e "${YELLOW}Warning: chsh command not found, cannot change current user shell.${RESET}"
fi

# 4. Set default shell for new users
DEFAULT_USERADD="/etc/default/useradd"
echo -e "${CYAN}Setting default shell for new users to /bin/zsh...${RESET}"
if [[ -f "$DEFAULT_USERADD" ]]; then
    # Attempt to replace existing SHELL= line or add it if missing
    if $SUDO grep -q '^SHELL=' "$DEFAULT_USERADD"; then
        $SUDO sed -i 's/^SHELL=\/.*$/SHELL=\/bin\/zsh/' "$DEFAULT_USERADD"
    else
        # If SHELL setting doesn't exist, append it.
        echo "SHELL=/bin/zsh" | $SUDO tee -a "$DEFAULT_USERADD" > /dev/null
    fi
    echo -e "${GREEN}Updated default user shell in $DEFAULT_USERADD.${RESET}"
else
    echo -e "${YELLOW}Could not find $DEFAULT_USERADD; new users may still default to bash.${RESET}"
fi

# ---------- SDDM Theme Setup ----------
banner "THEME"
echo -e "${CYAN}Skipping custom SDDM theme installation.${RESET}"
echo -e "${BLUE}The system's default SDDM theme will be retained.${RESET}"
sudo pacman -Syu --noconfirm --needed sddm
sudo systemctl enable sddm
# ---------- final cleanup & done ----------
rm -rf "$TMP"

banner "DONE"
echo -e "${BLUE}Installation complete!${RESET} ${MAGENTA}Welcome to aserdev-os 🚀${RESET}"
echo -e "${YELLOW}Tip: Reboot to apply GRUB/SDDM and ZSH changes.${RESET}"
