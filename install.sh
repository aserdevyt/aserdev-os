#!/usr/bin/bash

#check if user is root or had sudo and if it is it will close the script

set -e 


if [ "$EUID" -eq 0 ]; then
    echo "❌ Do NOT run this as root!"
    exit 1
fi

echo "next section"

# updating

echo "updating your os"

sudo pacman -Syu --noconfirm 


if [ $? -eq 0 ]; then
    echo "✅ updated"
else
    echo "❌ retrying"
    sudo pacman -Syu --noconfirm
    if [ $? -eq 0 ]; then
        echo "✅ updated"
    else
        echo "❌ failed to update please find a source of stable wifi"
        exit 1
    fi
fi

sudo pacman -S --noconfirm --needed git figlet wget curl vi vim nano  base-devel

if [ $? -eq 0 ]; then
    echo "✅ installed dependencies"
else
    echo "❌ failed to install dependencies"
    sudo pacman -S --noconfirm --needed git figlet wget curl vi vim nano  man base-devel
    if [ $? -eq 0 ]; then
        echo "✅ installed dependencies"
    else
        echo "❌ failed to install dependencies"
        exit 1
    fi
fi

echo "next section" 

figlet "installation"

echo "installing alot of packages"

sudo pacman -Syu --noconfirm --needed git figlet wget curl vi vim nano  man base-devel aria2 yt-dlp jdk-openjdk rust bash base 

if [ $? -eq 0 ]; then
    echo "✅ installed packages"
else
    echo "❌ failed to install packages"
    sudo pacman -Syu --noconfirm --needed git figlet wget curl vi vim nano  man base-devel aria2 yt-dlp jdk-openjdk rust bash base
    if [ $? -eq 0 ]; then
        echo "✅ installed packages"
    else
        echo "❌ failed to install packages"
        exit 1
    fi
fi

echo "next section"

figlet "configs"

desktop_environment=""


echo "choose your de"
echo "1) KDE"
echo "2) Gnome"
echo "3) XFCE"
echo "4) hyprland"

read desktop_environment



if [ "$desktop_environment" == "1" ]; then
    echo "You have selected KDE"
    sudo pacman -Syu --noconfirm --needed plasma sddm 
    sudo systemctl enable sddm
    if [ $? -eq 0 ]; then
        echo "✅ KDE installed successfully"
    else
        echo "❌ Failed to install KDE"
        exit 1
    fi
elif [ "$desktop_environment" == "2" ]; then
    echo "You have selected Gnome"
    sudo pacman -Syu --noconfirm --needed gnome gdm
    sudo systemctl enable gdm
    if [ $? -eq 0 ]; then
        echo "✅ Gnome installed successfully"
    else
        echo "❌ Failed to install Gnome"
        exit 1
    fi
elif [ "$desktop_environment" == "3" ]; then
    echo "You have selected XFCE"
    sudo pacman -Syu --noconfirm --needed xfce4 xfce4-goodies lightdm
    sudo systemctl enable lightdm
    if [ $? -eq 0 ]; then
        echo "✅ XFCE installed successfully"
    else
        echo "❌ Failed to install XFCE"
        exit 1
    fi
elif [ "$desktop_environment" == "4" ]; then
    echo "You have selected Hyprland"
    sudo pacman -Syu --noconfirm --needed hyprland sddm hyprpaper waybar swaync xdg-desktop-portal xdg-desktop-portal-hyprland
    sudo systemctl enable sddm
    if [ $? -eq 0 ]; then
        echo "✅ Hyprland installed successfully"
    else
        echo "❌ Failed to install Hyprland"
        exit 1
    fi
else
    echo "Invalid selection"
    echo "skipping using tty"
    
fi
 
echo "next section"

figlet "renaming the os"

wget https://raw.githubusercontent.com/aserdevyt/aserdev-os/refs/heads/main/os-release 

sudo rm /etc/os-release

sudo cp os-release /etc/os-release

cat /etc/os-release

echo "next section" 

figlet "themes"

echo "would you like a grub theme?"

read grub_theme

if [ "$grub_theme" == "yes" ]; then
    echo "You have selected a grub theme"
    echo "install chris titus tech temes shout out to him" 
    git clone https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes
    cd Top-5-Bootloader-Themes  
    sudo ./install.sh
    if [ $? -eq 0 ]; then
        echo "✅ Grub theme installed successfully"
    else
        echo "❌ Failed to install grub theme"
        exit 1
    fi
    cd ~
else
    echo "Skipping grub theme installation"
fi

echo "next section"

echo "would you like a plymouth theme?"

read plymouth_theme

if [ "$plymouth_theme" == "yes" ]; then
    echo "You have selected a plymouth theme"
    sudo pacman -Syu --noconfirm --needed plymouth
    sudo sed -i 's/HOOKS=(/HOOKS=(plymouth /' /etc/mkinitcpio.conf && \
sudo mkinitcpio -P && \
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash /' /etc/default/grub && \
sudo grub-mkconfig -o /boot/grub/grub.cfg && \
sudo plymouth-set-default-theme -R spinner

    if [ $? -eq 0 ]; then
        echo "✅ Plymouth theme installed successfully"
    else
        echo "❌ Failed to install plymouth theme"
        exit 1
    fi
else
    echo "Skipping plymouth theme installation"
fi

echo "next section"

figlet "aur"

git clone https://aur.archlinux.org/yay.git

cd yay

makepkg -si --noconfirm

cd ~

echo "next section"

figlet "shell"

echo "choose a shell"
echo "1:zsh"
echo "2:fish"
echo "3:ash-shell(experemintal)"
echo "4:bash"

shell_choice=""

read shell_choice

if [ "$shell_choice" == "1" ]; then
    echo "You have selected zsh"
    sudo pacman -Syu --noconfirm --needed zsh
    chsh -s /usr/bin/zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k && \
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting && \
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc && \
sed -i 's/^plugins=(.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

    if [ $? -eq 0 ]; then
        echo "✅ zsh installed successfully"
    else
        echo "❌ Failed to install zsh"
        exit 1
    fi
elif [ "$shell_choice" == "2" ]; then
    echo "You have selected fish"
    sudo pacman -Syu --noconfirm --needed fish
    chsh -s /usr/bin/fish
    if [ $? -eq 0 ]; then
        echo "✅ fish installed successfully"
    else
        echo "❌ Failed to install fish"
        exit 1
    fi
elif [ "$shell_choice" == "3" ]; then
    echo "You have selected ash-shell"
    yay -Syu --noconfirm --needed ash-shell-git
    chsh -s /usr/bin/ash
    if [ $? -eq 0 ]; then
        echo "✅ ash-shell installed successfully"
    else
        echo "❌ Failed to install ash-shell"
        exit 1
    fi
elif [ "$shell_choice" == "4" ]; then
    echo "You have selected bash"
    sudo pacman -Syu --noconfirm --needed bash
    chsh -s /usr/bin/bash
    if [ $? -eq 0 ]; then
        echo "✅ bash installed successfully"
    else
        echo "❌ Failed to install bash"
        exit 1
    fi
else
    echo "Invalid selection keeping current shell"

fi

figlet "REPOS"


echo "installing chaotic aur"

sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
    echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf
    sudo pacman -Syu
fi

echo "installing blackarch"

# Run https://blackarch.org/strap.sh as root and follow the instructions.

 curl -O https://blackarch.org/strap.sh
# Verify the SHA1 sum

 echo bbf0a0b838aed0ec05fff2d375dd17591cbdf8aa strap.sh | sha1sum -c
# Set execute bit

 chmod +x strap.sh
# Run strap.sh

 sudo ./strap.sh
# Enable multilib following https://wiki.archlinux.org/index.php/Official_repositories#Enabling_multilib and run:

 sudo pacman -Syu


figlet packages


echo "choose a browser"

echo "1:microsoft-edge-stable(recommended)"
echo "2:firefox"
echo "3:chromium"
echo "4:zen-browser"

browser=""

read browser

if [ "$browser" == "1" ]; then
    echo "You have selected microsoft-edge-stable"
    sudo pacman -Syu --noconfirm --needed microsoft-edge-stable
elif [ "$browser" == "2" ]; then
    echo "You have selected firefox"
    sudo pacman -Syu --noconfirm --needed firefox
elif [ "$browser" == "3" ]; then
    echo "You have selected chromium"
    sudo pacman -Syu --noconfirm --needed chromium
elif [ "$browser" == "4" ]; then
    echo "You have selected zen-browser"
    sudo pacman -Syu --noconfirm --needed zen-browser-bin
else
    echo "Invalid selection"
    echo "no browser for you"
fi

figlet "extras"

echo "would you like 'brokefetch' from 'https://github.com/Szerwigi1410/brokefetch'"

read -p "Install brokefetch? (y/n): " install_brokefetch

if [ "$install_brokefetch" == "y" ]; then
    yay -Syu --noconfirm brokefetch-git
fi


echo "you like gimp,kdenlive?" 

read -p "Install gimp and kdenlive? (y/n): " install_gimp_kdenlive

if [ "$install_gimp_kdenlive" == "y" ]; then
    yay -Syu --noconfirm gimp kdenlive
fi

echo "would you like to install any additional packages? (y/n)"
read -p "Install additional packages? (y/n): " install_additional_packages

if [ "$install_additional_packages" == "y" ]; then
    yay -Syu --noconfirm obs-studio qt5ct vlc vlc-plugins-all discord thunar visual-studio-code-bin bauh htop flatseal libreoffice-fresh 
fi

echo "done"

echo "would you like to install any other packages? (y/n)"

echo "say the packages names"
read -p "Install other packages? (y/n): " install_other_packages

if [ "$install_other_packages" == "y" ]; then
    read -p "Enter the package names (space-separated): " other_packages
    yay -Syu --noconfirm $other_packages
fi

echo "please restart"