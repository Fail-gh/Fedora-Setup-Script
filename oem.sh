#!/bin/bash
gsettings set org.gnome.shell.window-switcher current-workspace-only false
gsettings set org.gnome.desktop.interface font-antialiasing rgba
gsettings set org.gnome.desktop.wm.preferences button-layout appmenu:minimize,maximize,close
gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"
gsettings set org.gnome.software packaging-format-preference "['RPM', 'flatpak']"

lsblk -ro name,type,fsroots | grep -v disk | grep -v NAME | grep -v / | cut -d' ' -f1 | grep -m3 "" > crypted
max=$(wc -l crypted | cut -d' ' -f1)
n=1
while [ $n -le $max ]
do
	echo "Insert oem and than select a disk encryption password(Minimum 8 characters):"
	part=$(sed -n ''$n'p' crypted)
	((n++))
	sudo cryptsetup luksChangeKey /dev/$part
done
sudo rm crypted

tpm=$(systemd-cryptenroll --tpm2-device=list | grep tpm)
PS3="-> "
if [ -z "$tpm" ]
then
	echo "No TPM available, Skipping..."
else 
	echo "Enable tpm decryption? (Auto unlock of disk/s at boot, but is less secure)"
	select tpmd in Yes No; do
		case $tpmd in
			Yes)	
				lsblk -ro name,type,fsroots | grep -v disk | grep -v NAME | grep -v / | cut -d' ' -f1 | grep -m3 "" > crypted
				max=$(wc -l crypted | cut -d' ' -f1)
				n=1
				while [ $n -le $max ]
				do
					part=$(sed -n ''$n'p' crypted)
					((n++))
					sudo systemd-cryptenroll /dev/$part --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=4+7
				done
				sudo rm crypted
				break;;
			No)
				break;;
			*)
				echo "Invalid option";;
		esac
	done
fi

sudo rm /etc/xdg/autostart/oem.desktop
sudo rm /usr/share/oem.sh
