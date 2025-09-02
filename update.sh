#!/bin/bash
cd ~

echo "Copying configurations..."
curl -O https://raw.githubusercontent.com/pikriawan/archlinux-hyprland/refs/heads/main/.config.tar.xz
tar -xf .config.tar.xz
rm .config.tar.xz

sed -i "s|@HOME@|$HOME|g" .config/hypr/hyprpaper.conf
sed -i "s|@HOME@|$HOME|g" .config/hypr/hyprlock.conf
sed -i "s|@HOME@|$HOME|g" .config/waybar/style.css

echo "Copying executables..."
curl -O https://raw.githubusercontent.com/pikriawan/archlinux-hyprland/refs/heads/main/local.tar.xz
tar -xf .local.tar.xz
rm .local.tar.xz

echo "Update successful"
