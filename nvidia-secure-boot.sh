#!/bin/sudo bash

echo 'Insert "nvidia" when asks for passwords (no echo)'

#Set MOK timer to infinite
mokutil --timeout -1

#Import MOK for NVIDIA driver with secure boot
mokutil --import /etc/pki/akmods/certs/public_key.der

#Create autostart for next part of the script

mv $HOME/.config/autostart/user-configuration $HOME/.config/autostart/user-configuration.desktop

#Remove old part of the script
rm $HOME/.config/autostart/nvidia-secure-boot.desktop

reboot
