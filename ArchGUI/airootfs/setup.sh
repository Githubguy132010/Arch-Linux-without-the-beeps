#!/bin/bash

# Install KDE, SDDM, and NetworkManager
pacman -Sy --noconfirm plasma sddm networkmanager

# Enable SDDM and NetworkManager services
systemctl enable sddm.service
systemctl enable NetworkManager.service

# Create a user with the same username as password
useradd -m -G wheel username
echo "username:username" | chpasswd

# Enable autologin for the user
mkdir -p /etc/systemd/system/getty@tty1.service.d/
echo -e "[Service]\nExecStart=\nExecStart=-/sbin/agetty --noclear --autologin username %I $TERM" > /etc/systemd/system/getty@tty1.service.d/override.conf
