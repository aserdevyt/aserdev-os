#!/usr/bin/env bash
# =============================================
#   AserDev Arch -> AserDevOS Transformation 😎
# =============================================
set -eEuo pipefail
trap 'error_handler $LINENO' ERR

error_handler() {
    echo -e "\033[0;31m[✘] Error on line $1 — script aborted!\033[0m"
    echo "If this keeps happening, open an issue: https://github.com/aserdevyt/aserdev-os/issues"
    exit 1
}

# -------------------------
# Colors & helpers
# -------------------------
RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"; CYAN="\e[36m"; RESET="\e[0m"
msg() { echo -e "${CYAN}[*]${RESET} $1"; }
ok()  { echo -e "${GREEN}[✔]${RESET} $1"; }
warn(){ echo -e "${YELLOW}[!]${RESET} $1"; }
err() { echo -e "${RED}[✘]${RESET} $1"; }

# -------------------------
# Robust spinner + runner
# -------------------------
run_with_spinner() {
    local tmplog
    tmplog="$(mktemp /tmp/aserdev-log.XXXXXX)"
    ( "$@" >"$tmplog" 2>&1 ) &
    local pid=$!
    while kill -0 "$pid" 2>/dev/null; do
        for c in '|/-\' ; do
            printf " [%c]  " "$c"
            sleep 0.08
            printf "\b\b\b\b\b\b"
        done
    done
    wait "$pid" || {
        echo
        err "Command failed: $*"
        echo "-------- command output (last 200 lines) --------"
        tail -n 200 "$tmplog" || true
        rm -f "$tmplog"
        exit 1
    }
    rm -f "$tmplog"
}

# -------------------------
# Safety: must NOT be root
# -------------------------
if [ "$EUID" -eq 0 ]; then
    err "Do NOT run this as root. Run as a normal user and the script will use sudo when needed."
    exit 1
fi

msg "Welcome to the ${YELLOW}AserDevOS Installer${RESET} "
# Default for this critical confirm is 'n' to avoid accidental runs.
read -r -p "⚠️  This will heavily modify your system. Continue? [y/N]: " confirm
confirm="${confirm:-N}"
if [[ "${confirm,,}" != "y" ]]; then
    warn "Aborting per user choice. No changes made."
    exit 0
fi

# -------------------------
# Update system first
# -------------------------
msg "Updating system packages (pacman sync + upgrade)..."
run_with_spinner sudo pacman -Syu --noconfirm
ok "System updated."

# -------------------------
# Reliable pacman install helper
# -------------------------
install_pkgs() {
    local pkgs=("$@")
    msg "Installing: ${pkgs[*]}"
    run_with_spinner sudo pacman -S --needed --noconfirm "${pkgs[@]}"
    ok "Installed: ${pkgs[*]}"
}

# -------------------------
# Base deps
# -------------------------
install_pkgs git figlet wget curl vim nano man base-devel aria2 yt-dlp jdk-openjdk rust bash

# -------------------------
# Desktop Environment
# -------------------------
msg "Choose your Desktop Environment (default: GNOME)"
echo -e "1) KDE\n2) GNOME (default)\n3) XFCE\n4) Hyprland\n5) Skip"
read -r -p "Enter number [2]: " de
de="${de:-2}"   # default 2 (GNOME)

case "$de" in
    1)
        install_pkgs plasma sddm
        run_with_spinner sudo systemctl enable sddm
        ok "KDE + sddm enabled"
        ;;
    2)
        install_pkgs gnome gdm
        run_with_spinner sudo systemctl enable gdm
        ok "GNOME + gdm enabled"
        ;;
    3)
        install_pkgs xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
        run_with_spinner sudo systemctl enable lightdm
        ok "XFCE + lightdm enabled"
        ;;
    4)
        install_pkgs hyprland waybar swaybg wofi xdg-desktop-portal xdg-desktop-portal-hyprland sddm
        run_with_spinner sudo systemctl enable sddm
        ok "Hyprland + sddm enabled"
        ;;
    5)
        warn "Skipping DE installation"
        ;;
    *)
        warn "Invalid option, skipping DE."
        ;;
esac

# -------------------------
# OS rename (backup first)
# -------------------------
msg "Renaming / branding OS to AserDevOS (backups created)"
sudo cp /etc/os-release /etc/os-release.bak
run_with_spinner wget -qO /tmp/aserdev-os-release https://raw.githubusercontent.com/aserdevyt/aserdev-os/refs/heads/main/os-release
run_with_spinner sudo cp /tmp/aserdev-os-release /etc/os-release
ok "OS release replaced (backup: /etc/os-release.bak)."

# -------------------------
# Install AserDev repo installer (single-line)
# -------------------------
msg "Installing AserDev repo items via your remote installer..."
run_with_spinner bash -c "bash <(curl -fsSL https://raw.githubusercontent.com/aserdevyt/aserdev-repo/refs/heads/main/install.sh)"
ok "AserDev repo install script executed."

# -------------------------
# Yay (installed via pacman per request)
# -------------------------
msg "Installing yay (via pacman as requested)..."
run_with_spinner sudo pacman -Syu --noconfirm yay
ok "yay installed (via pacman)."

# -------------------------
# Shell choice + setup
# -------------------------
msg "Choose your shell (default: zsh)"
echo -e "1) zsh (default)\n2) fish\n3) ash-shell (experimental)\n4) bash\n5) Skip"
read -r -p "Enter number [1]: " shell_choice
shell_choice="${shell_choice:-1}"  # default zsh

case "$shell_choice" in
    1)
        install_pkgs zsh
        run_with_spinner chsh -s /usr/bin/zsh "$USER"
        run_with_spinner sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        run_with_spinner git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
        run_with_spinner git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
        run_with_spinner git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
        if [ -f "$HOME/.zshrc" ]; then cp "$HOME/.zshrc" "$HOME/.zshrc.aserdev.bak"; fi
        if grep -q '^ZSH_THEME=' "$HOME/.zshrc" 2>/dev/null; then
            sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
        else
            echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$HOME/.zshrc"
        fi
        if grep -q '^plugins=' "$HOME/.zshrc" 2>/dev/null; then
            sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
        else
            echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' >> "$HOME/.zshrc"
        fi
        grep -qxF 'alias ll="exa -lh"' "$HOME/.zshrc" || echo 'alias ll="exa -lh"' >> "$HOME/.zshrc"
        grep -qxF 'alias cat="bat"' "$HOME/.zshrc" || echo 'alias cat="bat"' >> "$HOME/.zshrc"
        grep -qxF 'neofetch' "$HOME/.zshrc" || echo 'neofetch' >> "$HOME/.zshrc"
        ok "zsh + oh-my-zsh + powerlevel10k + plugins installed"
        ;;
    2)
        install_pkgs fish
        run_with_spinner chsh -s /usr/bin/fish "$USER"
        ok "fish set as default shell"
        ;;
    3)
        warn "ash-shell is an AUR package; attempting to install via yay..."
        run_with_spinner yay -S --noconfirm ash-shell-git || warn "ash-shell install failed via yay; skip if not available."
        run_with_spinner chsh -s /usr/bin/ash "$USER" || true
        ok "ash-shell attempt finished"
        ;;
    4)
        install_pkgs bash
        run_with_spinner chsh -s /usr/bin/bash "$USER"
        ok "bash set as default shell"
        ;;
    5)
        warn "Keeping current shell."
        ;;
    *)
        warn "Invalid choice, keeping current shell."
        ;;
esac

# -------------------------
# GRUB theme (optional) - default: n
# -------------------------
read -r -p "Install a GRUB theme? [y/N]: " grub
grub="${grub:-N}"
if [[ "${grub,,}" == "y" ]]; then
    msg "Installing GRUB theme (Top-5-Bootloader-Themes)..."
    run_with_spinner git clone https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes /tmp/Top-5-Bootloader-Themes
    pushd /tmp/Top-5-Bootloader-Themes >/dev/null || true
    run_with_spinner sudo ./install.sh || warn "GRUB theme install script failed; check output."
    popd >/dev/null || true
    run_with_spinner rm -rf /tmp/Top-5-Bootloader-Themes
    ok "GRUB theme step complete"
else
    warn "Skipping GRUB theme"
fi

# -------------------------
# Plymouth (optional) - default: n
# -------------------------
read -r -p "Install Plymouth splash theme? [y/N]: " plymouth
plymouth="${plymouth:-N}"
if [[ "${plymouth,,}" == "y" ]]; then
    install_pkgs plymouth
    sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.bak || true
    sudo cp /etc/default/grub /etc/default/grub.bak || true
    if ! grep -q "plymouth" /etc/mkinitcpio.conf; then
        sudo sed -i 's/HOOKS=(/HOOKS=(plymouth /' /etc/mkinitcpio.conf || warn "Could not modify mkinitcpio.conf automatically"
    fi
    run_with_spinner sudo mkinitcpio -P
    if ! grep -q "quiet splash" /etc/default/grub; then
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash /' /etc/default/grub || warn "Could not modify grub default cmdline automatically"
    fi
    run_with_spinner sudo grub-mkconfig -o /boot/grub/grub.cfg || warn "grub-mkconfig failed"
    run_with_spinner sudo plymouth-set-default-theme -R spinner || warn "plymouth theme set failed"
    ok "Plymouth installed (backups created)"
else
    warn "Skipping Plymouth"
fi

# -------------------------
# Browsers (default: Firefox -> 2)
# -------------------------
msg "Choose your browser (default: Firefox)"
echo -e "1) Edge\n2) Firefox (default)\n3) Chromium\n4) Zen Browser\n5) Skip"
read -r -p "Enter number [2]: " browser
browser="${browser:-2}"

case "$browser" in
    1) install_pkgs microsoft-edge-stable ;;
    2) install_pkgs firefox ;;
    3) install_pkgs chromium ;;
    4) run_with_spinner yay -S --noconfirm zen-browser-bin || warn "zen-browser-bin not available via yay";;
    5) warn "Skipping browser." ;;
    *) warn "Invalid choice, skipping." ;;
esac
# -------------------------
# Extras: brokefetch (via pacman) - default: Y
# -------------------------
read -r -p "Install brokefetch? [Y/n]: " bro
bro="${bro:-Y}"   # default Y when Enter is pressed
if [[ "${bro,,}" == "y" ]]; then
    msg "Installing brokefetch via pacman..."
    run_with_spinner sudo pacman -Syu --noconfirm brokefetch || warn "brokefetch install failed"
    ok "brokefetch installed (via pacman)"
else
    warn "Skipping brokefetch"
fi


# -------------------------
# GIMP + Kdenlive - default: n
# -------------------------
read -r -p "Install GIMP + Kdenlive? [y/N]: " gk
gk="${gk:-N}"
if [[ "${gk,,}" == "y" ]]; then
    run_with_spinner sudo pacman -S --needed --noconfirm gimp kdenlive || warn "gimp/kdenlive install had issues"
    ok "GIMP + Kdenlive done"
fi

# -------------------------
# Extra recommended packages - default: n
# -------------------------
read -r -p "Install extra recommended packages (obs, vlc, discord, libreoffice, etc)? [y/N]: " extra
extra="${extra:-N}"
if [[ "${extra,,}" == "y" ]]; then
    run_with_spinner yay -S --noconfirm obs-studio vlc discord thunar visual-studio-code-bin bauh htop flatseal libreoffice-fresh || warn "Some extras failed; check output."
    ok "Extra recommended packages attempted"
fi

msg "All done! 🎉"
echo -e "${YELLOW}Reminder:${RESET} Reboot recommended. If you changed shell, log out/in or reboot to apply."
ok "Script finished."
