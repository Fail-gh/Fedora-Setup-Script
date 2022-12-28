#!/bin/bash
echo "Insert your password when asks for passwords"
sudo mokutil --timeout -1
sudo mokutil --import --timeout -1 /etc/pki/akmods/certs/public_key.der
sudo sh -c "echo '[Desktop Entry]
Name=TPMDecryption
GenericName=Setup tpm decryption
Exec=/usr/share/td.sh
Terminal=true
Type=Application
X-GNOME-Autostart-enabled=true' > /etc/xdg/autostart/td.desktop"
sudo rm /etc/xdg/autostart/nsb.desktop
sudo rm /usr/share/nsb.sh
reboot
