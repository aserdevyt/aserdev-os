#!/usr/bin/bash

#check if user is root or had sudo and if it is it will close the script


if [ "$EUID" -eq 0 ]; then
    echo "❌ Do NOT run this as root!"
    exit 1
fi

clear

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

clear 

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

clear

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
 
clear

figlet "renaming the os"

