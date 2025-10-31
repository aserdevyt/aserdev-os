#!/usr/bin/env bash
set -euo pipefail

echo "🔥 aserdev-os Postinstall Script Starting..."

# Update pacman.conf
curl -fsSL https://raw.githubusercontent.com/aserdevyt/aserdev-os/refs/heads/main/pacman.conf -o /etc/pacman.conf.new
mv -f /etc/pacman.conf.new /etc/pacman.conf
echo "✅ pacman.conf updated"

# Run GRUB chaos
curl -fsSL https://raw.githubusercontent.com/aserdevyt/aserdev-os/refs/heads/main/grub.sh -o /root/grub.sh
chmod +x /root/grub.sh
bash /root/grub.sh
echo "💀 grub.sh executed successfully"

# Replace os-release
curl -fsSL https://raw.githubusercontent.com/aserdevyt/aserdev-os/refs/heads/main/os-release -o /etc/os-release
echo "✅ os-release replaced"

echo "🎉 All done! System ready to boot into chaos mode."
