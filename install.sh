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
    echo -e "${YELLOW}No supported package manager detected (pacman/apt). Please install git/figlet/curl/wget manually.${RESET}"
  fi
}

# Only install what we actually need
install_packages git figlet curl wget

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

# ---------- dotfiles (clone into invoker's home & run installer as invoker) ----------
DOTFILES_GIT="https://github.com/aserdevyt/aserdev-dotfiles.git"
DOTFILES_DIR="$INVOKER_HOME/aserdev-dotfiles"

echo -e "${CYAN}Setting up dotfiles for user ${INVOKER}...${RESET}"
if [[ -d "$DOTFILES_DIR" ]]; then
  echo -e "${YELLOW}Existing dotfiles found, removing...${RESET}"
  rm -rf "$DOTFILES_DIR"
fi

# clone as the invoking user (so file ownership is right)
if [[ "$INVOKER" != "$(id -un)" ]]; then
  # we have a different invoker (script run under sudo)
  $SUDO -u "$INVOKER" git clone --depth=1 "$DOTFILES_GIT" "$DOTFILES_DIR" || echo -e "${YELLOW}Dotfiles clone failed.${RESET}"
else
  git clone --depth=1 "$DOTFILES_GIT" "$DOTFILES_DIR" || echo -e "${YELLOW}Dotfiles clone failed.${RESET}"
fi

# Run dotfiles install if present and executable
if [[ -f "$DOTFILES_DIR/install" && -x "$DOTFILES_DIR/install" ]]; then
  echo -e "${CYAN}Running dotfiles installer (silent)...${RESET}"
  if [[ "$INVOKER" != "$(id -un)" ]]; then
    # run as invoker
    $SUDO -u "$INVOKER" bash -c "cd '$DOTFILES_DIR' && ./install --silent" || echo -e "${RED}Dotfiles install failed.${RESET}"
  else
    (cd "$DOTFILES_DIR" && ./install --silent) || echo -e "${RED}Dotfiles install failed.${RESET}"
  fi
else
  echo -e "${YELLOW}No install script in dotfiles repo — manual setup may be required.${RESET}"
fi

# ---------- SDDM + Catppuccin Mocha theme ----------
banner "THEME"
echo -e "${BLUE}Preparing Catppuccin Mocha (Mauve) SDDM theme install...${RESET}"

# Ensure sddm exists (install if missing)
if ! command -v sddm &>/dev/null; then
  echo -e "${YELLOW}SDDM not detected. Installing sddm...${RESET}"
  install_packages sddm
else
  echo -e "${GREEN}SDDM detected.${RESET}"
fi

# Download and run the Catppuccin mocha installer from your repo (safer: download first)
CATP_URL="https://raw.githubusercontent.com/aserdevyt/aserdev-os/main/install_catppuccin_mocha.sh"
CATP_LOCAL="$TMP/install_catppuccin_mocha.sh"

echo -e "${CYAN}Downloading Catppuccin Mocha installer...${RESET}"
curl -fsSL "$CATP_URL" -o "$CATP_LOCAL"

if [[ -s "$CATP_LOCAL" ]]; then
  echo -e "${CYAN}Running Catppuccin installer as root...${RESET}"
  $SUDO bash "$CATP_LOCAL" || echo -e "${RED}Catppuccin installer failed.${RESET}"
else
  echo -e "${YELLOW}Failed to download Catppuccin installer; skipping theme setup.${RESET}"
fi

# ---------- final cleanup & done ----------
rm -rf "$TMP"

banner "DONE"
echo -e "${BLUE}Installation complete!${RESET} ${MAGENTA}Welcome to aserdev-os 🚀${RESET}"
echo -e "${YELLOW}Tip: Reboot to apply GRUB/SDDM changes.${RESET}"
