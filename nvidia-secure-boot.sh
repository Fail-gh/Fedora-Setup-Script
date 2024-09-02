#!/bin/sudo bash

echo 'Insert "nvidia" when asks for passwords (no echo/feedback/* when typing password)'

#Set MOK timer to infinite
mokutil --timeout -1

#Import MOK for NVIDIA driver with secure boot
mokutil --import /etc/pki/akmods/certs/public_key.der

#Create autostart for next part of the script
mv $PWD/.config/autostart/user-configuration $PWD/.config/autostart/user-configuration.desktop

#Remove old part of the script
rm $PWD/.config/autostart/nvidia-secure-boot.desktop

reboot
