#!/bin/bash
set -e

cd ~

echo "Installing yay..."
sudo pacman -S --needed --noconfirm base-devel git
sudo pacman -S --needed --noconfirm --asdeps go rust

if [ ! -d "yay" ]; then
    git clone https://aur.archlinux.org/yay.git
fi

cd yay
makepkg -sirc --noconfirm
cd ~

echo "Installing packages..."
yay -S --needed --noconfirm hyprland hyprpaper hypridle hyprlock xdg-desktop-portal-hyprland hyprpolkitagent uwsm libnewt dunst pipewire wireplumber qt5-wayland qt6-wayland inter-font ttf-jetbrains-mono noto-fonts ttf-noto-nerd waybar rofi-wayland cliphist nautilus xdg-desktop-portal-gtk wiremix grim slurp imagemagick wayfreeze-git brightnessctl jq gvfs wget tree man-db nodejs-lts-jod npm jdk-openjdk php apache php-apache mariadb alacritty htop blueberry visual-studio-code-bin firefox baobab decibels evince gnome-calculator gnome-calendar gnome-clocks gnome-disk-utility gnome-maps gnome-music gnome-text-editor gnome-weather loupe snapshot sushi totem file-roller

yay -S --needed --noconfirm --asdeps pipewire-pulse gvfs-mtp noto-fonts-cjk noto-fonts-emoji noto-fonts-extra arj binutils bzip3 cdrtools cpio dpkg lhasa lrzip 7zip rpmextract squashfs-tools unace unrar unzip zip

echo "Enabling services..."
sudo systemctl enable bluetooth.service
systemctl --user enable hypridle.service
systemctl --user enable hyprpolkitagent.service

echo "Copying configurations..."
curl -O https://raw.githubusercontent.com/pikriawan/archlinux-hyprland/refs/heads/main/.config.tar.xz
tar -xf .config.tar.xz
rm .config.tar.xz

sed -i "s|@HOME@|$HOME|g" .config/hypr/hyprpaper.conf
sed -i "s|@HOME@|$HOME|g" .config/hypr/hyprlock.conf
sed -i "s|@HOME@|$HOME|g" .config/waybar/style.css

echo "Copying local files..."
curl -O https://raw.githubusercontent.com/pikriawan/archlinux-hyprland/refs/heads/main/.local.tar.xz
tar -xf .local.tar.xz
rm .local.tar.xz

echo "Copying Material fonts..."
mkdir -p .local/share/fonts/MaterialSymbolsOutlined
curl -o .local/share/fonts/MaterialSymbolsOutlined/MaterialSymbolsOutlined_28pt-Regular.ttf https://raw.githubusercontent.com/pikriawan/archlinux-hyprland/refs/heads/main/MaterialSymbolsOutlined_28pt-Regular.ttf

echo "Configuring applications..."

# GTK
gsettings set org.gnome.desktop.interface color-scheme prefer-dark

# Visual Studio Code
mkdir -p .local/share/applications
sed 's/Exec=\/usr\/bin\/code %F/Exec=\/usr\/bin\/code --ozone-platform=wayland %F/g' /usr/share/applications/code.desktop > .local/share/applications/code.desktop
sed -i 's/Exec=\/usr\/bin\/code --new-window %F/Exec=\/usr\/bin\/code --new-window --ozone-platform=wayland %F/g' .local/share/applications/code.desktop 

# PHP
echo -e "extension=iconv\nextension=mysqli\nextension=pdo_mysql" | sudo tee /etc/php/conf.d/extensions.ini

# Apache
mkdir -p .backup

if [ ! -f ".backup/httpd.conf" ]; then
    sudo cp /etc/httpd/conf/httpd.conf .backup
fi

sed 's/LoadModule mpm_event_module/#LoadModule mpm_event_module/g' .backup/httpd.conf |
sed 's/#LoadModule mpm_prefork_module/LoadModule mpm_prefork_module/g' |
sed 's/mod_rewrite.so/mod_rewrite.so\nLoadModule php_module modules\/libphp.so\nAddHandler php-script .php/g' |
sed 's/*.conf/*.conf\nInclude conf\/extra\/php_module.conf/g' |
sudo tee /etc/httpd/conf/httpd.conf

# MariaDB
sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
sudo systemctl start mariadb.service
sudo mariadb -u root <<EOF
CREATE USER IF NOT EXISTS 'admin'@'localhost' IDENTIFIED BY '';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
sudo systemctl stop mariadb.service

# UWSM
if [ -z "$(grep 'uwsm' .bash_profile)" ]; then
    echo -e "\nif uwsm check may-start; then\n    exec uwsm start hyprland-uwsm.desktop > /dev/null\nfi" >> .bash_profile
fi

# PATH
if [ -z "$(grep 'export' .bashrc)" ]; then
    echo -e "\nexport PATH=\$HOME/.local/bin:\$PATH" >> .bashrc
fi

# Silent boot
if [ ! -f ".backup/mkinitcpio.conf" ]; then
    sudo cp /etc/mkinitcpio.conf .backup
fi

sed 's/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)/#HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)\nHOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block filesystems)/g' .backup/mkinitcpio.conf |
sudo tee /etc/mkinitcpio.conf
sudo mkinitcpio -P

echo "Cleaning up..."

if [ ! -z "$(yay -Qdtq)" ]; then
    yay -Rns --noconfirm $(yay -Qdtq)
fi

yes | yay -Scc
rm -r yay
sudo rm -rf .backup

echo "Installation finished. Please reboot the computer"
