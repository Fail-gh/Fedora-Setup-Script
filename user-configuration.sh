#!/bin/bash

#Install GNOME Tweaks, Extension Manager, Menu Libre a tool to manage GNOME menu and Gear Lever a tool to use appimage more easily
pkcon install gnome-tweaks -y

flatpak install flathub com.mattjakeman.ExtensionManager it.mijorus.gearlever com.github.tchx84.Flatseal org.bluesabre.MenuLibre -y

#Check TPM and asks if enable auto decryption
luks=$(lsblk | grep luks)
tpm=$(systemd-cryptenroll --tpm2-device=list | grep tpm)

if [ -n "$luks" ]
then
	if [ -n "$tpm" ]
	then
		PS3="-> "
		echo "Enable tpm decryption? (Auto unlock of disk/s at boot, but is less secure)"
		select tpmd in Yes No
		do
			case $tpmd in
				Yes)
					sudo blkid -t TYPE=crypto_LUKS | cut -d':' -f1 | cut -d'/' -f3 > crypted
					max=$(wc -l < crypted)
					for ((n=1; n<=max; n++))
					do
						part=$(sed -n "${n}p" crypted)
						sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=2+5+6 /dev/$part
					done
					sudo awk '{sub("none","-",$3);print}' /etc/crypttab > crypttab
					sudo awk '{sub("discard","tpm2-device=auto,discard",$4);print}' crypttab > crypttab2
					sudo cp crypttab2 /etc/crypttab
					rm crypted crypttab crypttab2
					echo "Please wait..."
					sudo grubby --args="rd.luks.options=tpm2-device=auto" --update-kernel=ALL
					sudo dracut -f
					break;;
				No)
					break;;
				*)
					echo "Invalid option"
					break;;
			esac
		done
	else
		echo "TPM not available"
	fi
else
	echo "No encrypted disk"
fi

rm $HOME/.config/autostart/user-configuration.desktop
