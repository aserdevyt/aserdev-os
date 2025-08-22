#!/usr/bin/env bash

# =============================================
#   AserDev Arch -> AserDevOS Transformation 😎
# =============================================

set -e

set -eEuo pipefail

trap 'error_handler $LINENO' ERR

error_handler() {
    echo -e "\033[0;31m[✘] Error on line $1 — script aborted!\033[0m"
    echo "retry again if this happends again report in https://github.com/aserdevyt/aserdev-os/issues"
    exit 1
}


# Colors 🎨
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

# Pretty echo
msg() { echo -e "${CYAN}[*]${RESET} $1"; }
ok() { echo -e "${GREEN}[✔]${RESET} $1"; }
warn() { echo -e "${YELLOW}[!]${RESET} $1"; }
err() { echo -e "${RED}[✘]${RESET} $1"; }

# Spinner 🌀
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while ps -p $pid &>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}


run_with_spinner() {
    ("$@") & 
    local pid=$!
    spinner $pid   # <--- you need this (with $pid)
    wait $pid
}


# =============================================
# Root check
# =============================================
if [ "$EUID" -eq 0 ]; then
    err "Do NOT run this as root! Run as a normal user with sudo."
    exit 1
fi

msg "Welcome to the ${YELLOW}AserDevOS Installer${RESET}!"
read -p "⚠️  This will heavily modify your system. Continue? (y/n): " confirm
[[ "$confirm" != "y" ]] && exit 1

# =============================================
# Safe Pacman Install Function
# =============================================
install_pkgs() {
    local packages="$@"
    msg "Installing: $packages"
    if run_with_spinner sudo pacman -S --needed --noconfirm $packages; then
        ok "$packages installed."
    else
        err "Failed to install $packages"
        exit 1
    fi
}

# =============================================
# Update System
# =============================================
msg "Updating system..."
run_with_spinner sudo pacman -Syu --noconfirm && ok "System updated!"

# =============================================
# Base Dependencies
# =============================================
install_pkgs git figlet wget curl vim nano man base-devel aria2 yt-dlp jdk-openjdk rust bash base

# =============================================
# Desktop Environments
# =============================================
msg "Choose your Desktop Environment:" 
echo -e "1) KDE\n2) Gnome\n3) XFCE\n4) Hyprland\n5) Skip"
read -p "Enter number: " de

case $de in
    1) install_pkgs plasma sddm && run_with_spinner sudo systemctl enable sddm && ok "KDE Ready";;
    2) install_pkgs gnome gdm && run_with_spinner sudo systemctl enable gdm && ok "Gnome Ready";;
    3) install_pkgs xfce4 xfce4-goodies lightdm && run_with_spinner sudo systemctl enable lightdm && ok "XFCE Ready";;
    4) install_pkgs hyprland sddm hyprpaper waybar swaync xdg-desktop-portal xdg-desktop-portal-hyprland && run_with_spinner sudo systemctl enable sddm && ok "Hyprland Ready";;
    5) warn "Skipping DE installation";;
    *) warn "Invalid option, skipping.";;
esac

# =============================================
# OS Rename (Backup First)
# =============================================
msg "Renaming OS to AserDevOS"
sudo cp /etc/os-release /etc/os-release.bak
wget -q https://raw.githubusercontent.com/aserdevyt/aserdev-os/refs/heads/main/os-release -O os-release
sudo cp os-release /etc/os-release && ok "OS Renamed (backup at /etc/os-release.bak)"

# =============================================
# Yay Setup
# =============================================
if ! command -v yay &>/dev/null; then
    msg "Installing yay (AUR helper)"
    git clone https://aur.archlinux.org/yay.git && cd yay && run_with_spinner makepkg -si --noconfirm && cd .. && rm -rf yay
    ok "yay installed"
else
    ok "yay already installed"
fi

# =============================================
# Shells
# =============================================
msg "Choose your shell:"
echo -e "1) zsh\n2) fish\n3) ash-shell (experimental)\n4) bash\n5) Skip"
read -p "Enter number: " shell_choice

case $shell_choice in
    1)
        install_pkgs zsh
        run_with_spinner chsh -s /usr/bin/zsh
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
        sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
        sed -i 's/^plugins=(.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
        ok "zsh with oh-my-zsh + plugins installed";;
    2) install_pkgs fish && run_with_spinner chsh -s /usr/bin/fish && ok "fish set!";;
    3) yay -S --noconfirm ash-shell-git && run_with_spinner chsh -s /usr/bin/ash && ok "ash-shell set!";;
    4) install_pkgs bash && run_with_spinner chsh -s /usr/bin/bash && ok "bash set!";;
    5) warn "Keeping current shell.";;
    *) warn "Invalid choice, keeping current shell.";;
esac

# =============================================
# GRUB Theme
# =============================================
read -p "Install a GRUB theme? (y/n): " grub
if [ "$grub" == "y" ]; then
    msg "Installing GRUB theme from Chris Titus Tech repo"
    git clone https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes
    cd Top-5-Bootloader-Themes
    run_with_spinner sudo ./install.sh
    cd .. && rm -rf Top-5-Bootloader-Themes
    ok "GRUB theme installed"
else
    warn "Skipping GRUB theme"
fi

# =============================================
# Plymouth Theme
# =============================================
read -p "Install Plymouth splash theme? (y/n): " plymouth
if [ "$plymouth" == "y" ]; then
    install_pkgs plymouth
    sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.bak
    sudo cp /etc/default/grub /etc/default/grub.bak
    sudo sed -i 's/HOOKS=(/HOOKS=(plymouth /' /etc/mkinitcpio.conf
    run_with_spinner sudo mkinitcpio -P
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash /' /etc/default/grub
    run_with_spinner sudo grub-mkconfig -o /boot/grub/grub.cfg
    run_with_spinner sudo plymouth-set-default-theme -R spinner
    ok "Plymouth installed (backups at mkinitcpio.conf.bak + grub.bak)"
else
    warn "Skipping Plymouth"
fi

# =============================================
# Browsers
# =============================================
msg "Choose your browser:"
echo -e "1) Edge\n2) Firefox\n3) Chromium\n4) Zen Browser\n5) Skip"
read -p "Enter number: " browser

case $browser in
    1) install_pkgs microsoft-edge-stable;;
    2) install_pkgs firefox;;
    3) install_pkgs chromium;;
    4) yay -S --noconfirm zen-browser-bin;;
    5) warn "Skipping browser.";;
    *) warn "Invalid choice, skipping.";;
esac

# =============================================
# Extras
# =============================================
read -p "Install brokefetch? (y/n): " bro
[[ "$bro" == "y" ]] && yay -S --noconfirm brokefetch-git

read -p "Install GIMP + Kdenlive? (y/n): " gk
[[ "$gk" == "y" ]] && yay -S --noconfirm gimp kdenlive

read -p "Install extra recommended packages (obs, vlc, discord, libreoffice, etc)? (y/n): " extra
[[ "$extra" == "y" ]] && yay -S --noconfirm obs-studio vlc discord thunar visual-studio-code-bin bauh htop flatseal libreoffice-fresh

msg "All done! 🎉 Please reboot your system."
