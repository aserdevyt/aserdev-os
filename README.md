# aserdev-os
## ⚠️work on progress don't use if you are not sure⚠️

this script will reaname your os and install [chaotic aur](https://aur.chaotic.cx/) and [blackarch](https://www.blackarch.org/downloads.html) and will install [chriss titus grub themes](https://christitus.com/bootloader-themes/) shout out to [him](https://christitus.com/)

## installation

make a fresh install of [archlinux](https://archlinux.org/) 
and make a minimal install with multilib and testing enabled and make a normal user account with sudo enabled
also install pipewire

after installation reboot into your minimal archinstall and run this

```bash
sudo pacman -Sy curl

sh -c "$(curl -fsSL https://raw.githubusercontent.com/aserdevyt/aserdev-os/main/install.sh)"
```

## issues

if something happends report it [here](https://github.com/aserdevyt/aserdev-os/issues)

## what the script installes

### essentials 

- git
- figlet
- wget
- curl
- vim
- nano
- man
- base-devel
- aria2
- yt-dlp
- jdk-openjdk
- rust
- bash
- base

### de/wm
 
- plasma
- sddm
- gnome
- gdm
- xfce4
- xfce4-goodies
- lightdm
- hyprland
- hyprpaper
- waybar
- swaync
- xdg-desktop-portal
- xdg-desktop-portal-hyprland

### aur

- yay (built from AUR via makepkg -si after cloning aur.archlinux.org/yay.git)

### shell

- zsh
- oh-my-zsh (installed via the official install script)
- powerlevel10k (cloned into Oh-My-Zsh custom themes)
- zsh-autosuggestions (cloned plugin)
- zsh-syntax-highlighting (cloned plugin)
- fish
- ash-shell-git (installed via yay)

### browsers

- microsoft-edge-stable
- firefox
- chromium
- zen-browser-bin (installed via yay)

### optional
  
- plymouth (optional if user chooses Plymouth)
- brokefetch-git (optional via yay)
- gimp (optional)
- kdenlive (optional)
- obs-studio (optional)
- vlc (optional)
- discord (optional)
- thunar (optional)
- visual-studio-code-bin (optional, via yay)
- bauh (optional)
- htop (optional)
- flatseal (optional)
- libreoffice-fresh (optional)
