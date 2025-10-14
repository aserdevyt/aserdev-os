#!/usr/bin/env bash
# install_catppuccin_mocha.sh
# Installs Catppuccin Mocha (Mauve) SDDM theme.
# Tries clone-first, falls back to downloading latest release asset if needed.
set -euo pipefail

# colors
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RESET="\033[0m"

# config
TMP_DIR="/tmp/catppuccin-sddm.$$"
THEME_DIR="/usr/share/sddm/themes"
FLAVOUR="mocha"
ACCENT="mauve"
WANTED_DIR="catppuccin-${FLAVOUR}-${ACCENT}"
REPO="https://github.com/catppuccin/sddm.git"
GITHUB_API="https://api.github.com/repos/catppuccin/sddm/releases/latest"

# helpers
die(){ echo -e "${RED}✖ $*${RESET}" >&2; exit 1; }
info(){ echo -e "${CYAN}➜ $*${RESET}"; }
ok(){ echo -e "${GREEN}✔ $*${RESET}"; }

# must be root
if [[ $EUID -ne 0 ]]; then
  die "Run this as root (sudo)."
fi

mkdir -p "$TMP_DIR"
trap 'rm -rf "$TMP_DIR"' EXIT

# ensure minimal tools
need_cmd() {
  command -v "$1" &>/dev/null || {
    PKG="$1"
    info "Missing $1 — attempting to install via package manager..."
    if command -v pacman &>/dev/null; then
      pacman -S --noconfirm --needed "$PKG"
    elif command -v apt &>/dev/null; then
      apt update && apt install -y "$PKG"
    else
      die "No supported package manager (pacman/apt). Install $1 manually."
    fi
  }
}

need_cmd git
need_cmd curl
need_cmd unzip

info "Attempting shallow clone of the repo (fast)..."
rm -rf "$TMP_DIR/clone" || true
git clone --depth=1 "$REPO" "$TMP_DIR/clone" || true

# 1) Try to find flavour dir inside the clone (some repos may include it)
info "Searching clone for the desired flavour directory..."
FOUND="$(find "$TMP_DIR/clone" -maxdepth 2 -type d -name "catppuccin-${FLAVOUR}*" -print -quit || true)"

if [[ -n "$FOUND" && -d "$FOUND" ]]; then
  info "Found flavour directory in repo: $FOUND"
  mkdir -p "$THEME_DIR"
  cp -r "$FOUND" "$THEME_DIR/" || die "Failed to copy theme dir to $THEME_DIR"
  ok "Installed $WANTED_DIR to $THEME_DIR"
  echo -e "${YELLOW}Set Current=$WANTED_DIR in /etc/sddm.conf or /etc/sddm.conf.d/ to enable it.${RESET}"
  exit 0
fi

info "Flavour not present in clone. Falling back to release download..."

# 2) Query GitHub releases for an asset matching "mocha" (we look for a zip)
# Note: we use the releases/latest API to find assets and their download URLs.
info "Querying GitHub releases for latest release..."
GH_JSON="$(curl -fsSL "$GITHUB_API")" || die "Failed to query GitHub releases (network / API error)."

# attempt to find an asset name containing 'mocha' (case-insensitive) and ending with .zip
ASSET_URL="$(echo "$GH_JSON" \
  | tr '\n' ' ' \
  | sed 's/\\//g' \
  | grep -oE '"browser_download_url":[^,]+' \
  | sed -E 's/.*"browser_download_url":[[:space:]]*"([^"]+)".*/\1/' \
  | grep -i "mocha" \
  | grep -iE "\.zip$" \
  | head -n1 || true)"

if [[ -z "$ASSET_URL" ]]; then
  # fallback: try predictable filenames for older releases:
  # first try catppuccin-mocha.zip (generic), then catppuccin-mocha-<accent>.zip
  POSSIBLE_URLS=(
    "https://github.com/catppuccin/sddm/releases/download/v1.1.2/catppuccin-mocha.zip"
    "https://github.com/catppuccin/sddm/releases/download/v1.1.2/catppuccin-mocha-mauve.zip"
    "https://github.com/catppuccin/sddm/releases/download/v1.0.0/catppuccin-mocha.zip"
    "https://github.com/catppuccin/sddm/releases/download/v1.0.0/catppuccin-mocha-mauve.zip"
  )
  for u in "${POSSIBLE_URLS[@]}"; do
    info "Trying fallback URL: $u"
    if curl -fsI "$u" &>/dev/null; then
      ASSET_URL="$u"
      break
    fi
  done
fi

if [[ -z "$ASSET_URL" ]]; then
  die "Couldn't discover a mocha release asset automatically. Open the repo releases and download the flavour zip manually: https://github.com/catppuccin/sddm/releases"
fi

info "Found asset: $ASSET_URL"
ZIP_LOCAL="$TMP_DIR/catppuccin-mocha.zip"
info "Downloading asset..."
curl -fsSL "$ASSET_URL" -o "$ZIP_LOCAL" || die "Failed to download asset."

info "Extracting zip..."
unzip -q "$ZIP_LOCAL" -d "$TMP_DIR/extracted" || die "Failed to unzip."

# Locate the flavour folder inside extracted content
info "Searching extracted files for flavour directory..."
FOUND2="$(find "$TMP_DIR/extracted" -maxdepth 3 -type d -name "catppuccin-${FLAVOUR}*" -print -quit || true)"

if [[ -z "$FOUND2" ]]; then
  echo -e "${YELLOW}Contents of extracted zip:${RESET}"
  find "$TMP_DIR/extracted" -maxdepth 2 -type d -printf ' - %p\n' || true
  die "Couldn't locate flavour directory inside the release archive."
fi

info "Found $FOUND2 — copying to $THEME_DIR..."
mkdir -p "$THEME_DIR"
cp -r "$FOUND2" "$THEME_DIR/" || die "Failed to copy theme."

ok "Installed $(basename "$FOUND2") → $THEME_DIR"

info "Writing SDDM config to select theme..."
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/aserdev-catppuccin.conf <<EOF
[Theme]
Current=$(basename "$FOUND2")
EOF

ok "Wrote /etc/sddm.conf.d/aserdev-catppuccin.conf"

echo -e "${YELLOW}Done. You may need to install qt6/qt5 qml deps for SDDM themes to work (see repo README). Reboot to see the login screen.${RESET}"
exit 0
