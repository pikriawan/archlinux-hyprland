#!/bin/bash
set -e

cd ~

echo "Installing yay..."
sudo pacman -S --noconfirm base-devel git
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ~

echo "Installing packages..."
yay -S --needed --noconfirm hyprland hyprpaper hypridle hyprlock xdg-desktop-portal-hyprland hyprpolkitagent uwsm libnewt dunst pipewire wireplumber qt5-wayland qt6-wayland inter-font ttf-jetbrains-mono noto-fonts ttf-noto-nerd waybar rofi-wayland cliphist nautilus xdg-desktop-portal-gtk wiremix espeakup brightnesscl jq gvfs wget tree man-db nodejs-lts-jod npm jdk-openjdk php apache php-apache mariadb alacritty htop blueberry visual-studio-code-bin baobab decibels gnome-calculator gnome-calendar gnome-clocks gnome-disk-utility gnome-maps gnome-music gnome-text-editor gnome-weather loupe papers showtime snapshot sushi file-roller

yay -S --needed --noconfirm --asdeps gvfs-mtp rtkit noto-fonts-cjk noto-fonts-emoji noto-fonts-extra arj binutils bzip3 cdrtools cpio dpkg lhasa lrzip 7zip rpmextract squashfs-tools unace unrar unzip zip

echo "Enabling services..."
sudo systemctl enable bluetooth.service
systemctl --user enable hypridle.service

echo "Copying configurations..."
curl -O https://raw.githubusercontent.com/pikriawan/archlinux-hyprland/refs/heads/main/.config.tar.xz
tar -xf .config.tar.xz
rm .config.tar.xz

sed -i "s|@HOME@|$HOME|g" .config/hypr/hyprpaper.conf
sed -i "s|@HOME@|$HOME|g" .config/hypr/hyprlock.conf
sed -i "s|@HOME@|$HOME|g" .config/waybar/style.css

echo "Copying executables..."
curl -O https://raw.githubusercontent.com/pikriawan/archlinux-hyprland/refs/heads/main/bin.tar.xz
tar -xf bin.tar.xz -C .local/bin
rm bin.tar.xz

echo "Configuring applications..."

# Speech dispatcher
spd-conf

# GTK
gsettings set org.gnome.desktop.interface color-scheme prefer-dark

# PHP
echo -e "extension=iconv\nextension=mysqli\nextension=pdo_mysql" | sudo tee /etc/php/conf.d/extensions.ini

# Apache
sudo sed -i 's/LoadModule mpm_event_module/#LoadModule mpm_event_module/g' /etc/httpd/conf/httpd.conf
sudo sed -i 's/#LoadModule mpm_prefork_module/LoadModule mpm_prefork_module/g' /etc/httpd/conf/httpd.conf
sudo sed -i 's/mod_rewrite.so/mod_rewrite.so\nLoadModule php_module modules\/libphp.so\nAddHandler php-script .php/g' /etc/httpd/conf/httpd.conf
sudo sed -i 's/*.conf/*.conf\nInclude conf\/extra\/php_module.conf/g' /etc/httpd/conf/httpd.conf

# MariaDB
sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
sudo systemctl start mariadb.service
sudo mariadb -u root <<EOF
CREATE USER 'admin'@'localhost' IDENTIFIED BY '';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
sudo systemctl stop mariadb.service

# UWSM
echo -e "\nif uwsm check may-start; then\n    exec uwsm start hyprland-uwsm.desktop > /dev/null\nfi" >> .bash_profile

# Silent boot
sudo sed -i 's/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)/#HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)\nHOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block filesystems)/g' /etc/mkinitcpio.conf
sudo mkinitcpio -P

echo "Cleaning up..."
yay -Rns $(yay -Qdtq)
yay -Scc

echo "Installation finished. Please reboot the computer"
