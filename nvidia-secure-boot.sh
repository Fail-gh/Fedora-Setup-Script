#!/bin/sudo bash

echo 'Insert "nvidia" when asks for passwords (no echo)'

#Set MOK timer to infinite
mokutil --timeout -1

#Import MOK for NVIDIA driver with secure boot
mokutil --import /etc/pki/akmods/certs/public_key.der

#Create autostart for next part of the script
echo "[Desktop Entry]
Name=User Configuration
Exec=/usr/user-configuration.sh
Terminal=true
Type=Application" > /home/$SUDO_USER/.config/autostart/user-configuration.desktop

#Remove old part of the script
rm /home/$SUDO_USER/.config/autostart/nvidia-secure-boot.desktop
reboot
