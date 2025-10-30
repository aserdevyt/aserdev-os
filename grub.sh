#!/usr/bin/env bash
# 💀 aserdev-OS GRUB Chaos Script v3 — dependency-safe & archinstall-friendly
set -euo pipefail

LOG=/tmp/aserdev-grub.log
: > "$LOG"

info()  { printf "\033[1;36m[INFO]\033[0m %s\n" "$*" | tee -a "$LOG"; }
warn()  { printf "\033[1;33m[WARN]\033[0m %s\n" "$*" | tee -a "$LOG" >&2; }
err()   { printf "\033[1;31m[ERR]\033[0m %s\n" "$*" | tee -a "$LOG" >&2; exit 1; }

# sanity
if [[ $EUID -ne 0 ]]; then
  err "Run me as root. Exiting."
fi

# helper: command check
cmd_exists() { command -v "$1" >/dev/null 2>&1; }

# pacman lock waiter (returns 0 if OK, 1 if still locked)
wait_for_pacman() {
  local tries=0 max=30
  while [[ -f /var/lib/pacman/db.lck && $tries -lt $max ]]; do
    info "pacman DB locked, waiting... ($tries/$max)"
    sleep 1
    tries=$((tries+1))
  done
  if [[ -f /var/lib/pacman/db.lck ]]; then
    warn "pacman DB still locked after $max sec — proceeding without installing packages."
    return 1
  fi
  return 0
}

# try to install a package via pacman if pacman exists and not locked
try_install() {
  local pkgs=("$@")
  if ! cmd_exists pacman; then
    warn "pacman not found — cannot auto-install: ${pkgs[*]}"
    return 1
  fi
  if ! wait_for_pacman; then
    warn "Skipping install of ${pkgs[*]} due to pacman lock."
    return 1
  fi

  info "Attempting: pacman -Sy --noconfirm ${pkgs[*]}"
  if ! pacman -Sy --noconfirm "${pkgs[@]}" >/tmp/aserdev-pacman.log 2>&1; then
    warn "pacman failed to install ${pkgs[*]} — check /tmp/aserdev-pacman.log"
    return 1
  fi
  return 0
}

# ensure minimum deps
REQ=(curl sed grep)
OPT=(figlet)
GRUB_PKG=(grub)

for c in "${REQ[@]}"; do
  if ! cmd_exists "$c"; then
    info "Missing required command: $c"
    try_install "$c" || warn "Missing required command $c and auto-install failed; script may be limited."
  fi
done

# ensure grub tools exist or try to install grub package
if ! cmd_exists grub-mkconfig; then
  info "grub-mkconfig not found — trying to install grub package"
  try_install "${GRUB_PKG[@]}" || warn "Could not install grub; regeneration may fail."
fi

# optional aesthetics
if ! cmd_exists figlet; then
  try_install figlet >/dev/null 2>&1 || true
fi

# logging header
info "Starting aserdev-OS grub script"
date | tee -a "$LOG"

# paths
GRUB_FILE="/etc/default/grub"
GRUB_CFG="/boot/grub/grub.cfg"
# fallback for some distros
if [[ -d /boot/grub2 && -f /boot/grub2/grub.cfg ]]; then
  GRUB_CFG="/boot/grub2/grub.cfg"
fi

# basic sanity checks before mutating files
if [[ ! -d /boot ]]; then
  warn "/boot not present — grub update might fail later. We'll still patch /etc/default/grub."
fi

# backup
if [[ -f "$GRUB_FILE" ]]; then
  cp -a "$GRUB_FILE" "${GRUB_FILE}.bak.$(date +%s)" && info "Backed up $GRUB_FILE"
else
  warn "$GRUB_FILE not found — creating a minimal one"
  cat > "$GRUB_FILE" <<'EOF'
# Minimal /etc/default/grub created by aserdev script
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="aserdev-OS"
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=7"
GRUB_CMDLINE_LINUX=""
EOF
fi

# SAFELY set/replace loglevel=7 in GRUB_CMDLINE_LINUX_DEFAULT
if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=' "$GRUB_FILE"; then
  # if loglevel present, replace it; else append before ending quote
  if grep -q 'loglevel=' "$GRUB_FILE"; then
    sed -Ei 's/(loglevel=)[^[:space:]]+/\17/g' "$GRUB_FILE"
  else
    sed -Ei 's/^(GRUB_CMDLINE_LINUX_DEFAULT=")([^"]*)"/\1\2 loglevel=7"/' "$GRUB_FILE"
  fi
else
  # append line if missing
  echo 'GRUB_CMDLINE_LINUX_DEFAULT="loglevel=7"' >> "$GRUB_FILE"
fi

# remove separate 'quiet' tokens from the default cmdline safely
sed -Ei 's/\bquiet\b ?//g' "$GRUB_FILE" || true

# normalize spaces inside quotes (remove double spaces)
sed -Ei 's/  +/ /g' "$GRUB_FILE" || true

info "Patched $GRUB_FILE, preview:"
grep -E 'GRUB_CMDLINE_LINUX_DEFAULT|GRUB_CMDLINE_LINUX' "$GRUB_FILE" | tee -a "$LOG"

# try to regenerate grub.cfg if possible
if cmd_exists grub-mkconfig; then
  info "Regenerating grub config..."
  if grub-mkconfig -o "$GRUB_CFG" >/tmp/aserdev-grub-update.log 2>&1; then
    info "grub.cfg updated at $GRUB_CFG"
  else
    warn "grub-mkconfig failed — see /tmp/aserdev-grub-update.log. Will keep patched /etc/default/grub for later."
  fi
else
  warn "grub-mkconfig not available — can't regenerate grub.cfg now."
fi

# rename visible menuentries occurrences of "Arch Linux" to "aserdev-OS" (non-destructive)
if [[ -f "$GRUB_CFG" ]]; then
  if grep -qi "Arch Linux" "$GRUB_CFG"; then
    # replace only the text, not whole lines
    sed -Ei 's/Arch Linux/aserdev-OS/g' "$GRUB_CFG" && info "Renamed 'Arch Linux' -> 'aserdev-OS' in $GRUB_CFG"
  else
    info "No 'Arch Linux' menu entries found in $GRUB_CFG"
  fi
else
  warn "$GRUB_CFG not found; skipping menuentry rename."
fi

# preview top menuentries
if [[ -f "$GRUB_CFG" ]]; then
  info "Top menuentries preview:"
  grep -i "menuentry" "$GRUB_CFG" | head -n 6 | tee -a "$LOG"
fi

info "Done. Log: $LOG"
printf "\n\033[1;32m✔️  GRUB chaos complete — script finished.\033[0m\n"
