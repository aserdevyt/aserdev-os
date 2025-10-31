#!/usr/bin/env bash
set -euo pipefail

echo "🔥 aserdev-os Postinstall Script Starting..."

# Ensure dependencies
if ! command -v curl &>/dev/null; then
    echo "📦 Installing curl..."
    pacman -Sy --noconfirm curl || (echo "💀 Failed to install curl" && exit 1)
fi

# Update pacman.conf safely
echo "🔧 Updating pacman.conf..."
curl -fsSL https://raw.githubusercontent.com/aserdevyt/aserdev-os/refs/heads/main/pacman.conf -o /etc/pacman.conf.new
mv -f /etc/pacman.conf.new /etc/pacman.conf
echo "✅ pacman.conf updated"

# Fetch and execute GRUB setup
echo "⚙️ Running GRUB setup..."
curl -fsSL https://raw.githubusercontent.com/aserdevyt/aserdev-os/refs/heads/main/grub.sh -o /root/grub.sh
chmod +x /root/grub.sh
bash /root/grub.sh || { echo "💀 grub.sh failed!"; exit 1; }
echo "💀 grub.sh executed successfully"

# Replace os-release
echo "🧾 Replacing os-release..."
curl -fsSL https://raw.githubusercontent.com/aserdevyt/aserdev-os/refs/heads/main/os-release -o /etc/os-release
echo "✅ os-release replaced"

echo "🎉 All done! System ready to boot into chaos mode. 🚀"
