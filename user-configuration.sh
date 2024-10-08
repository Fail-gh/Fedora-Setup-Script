#!/bin/bash

#Install, if on GNOME, Extension Manager, libadwaita theme GTK-3 flatpak apps and Gear Lever a tool to use appimage more easily
if [ $XDG_CURRENT_DESKTOP = "GNOME" ]
then
	pkcon install gnome-tweaks -y
	pkcon install menulibre -y

	flatpak install flathub com.mattjakeman.ExtensionManager it.mijorus.gearlever com.github.tchx84.Flatseal -y
fi

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

nvidia=$(lspci | grep NVIDIA)
secure_boot=$(mokutil --sb-state | cut -d' ' -f2)

if [[ -n "$nvidia" && $secure_boot == "enabled" ]]
then
	sudo mokutil --timeout 10
fi

rm $HOME/.config/autostart/user-configuration.desktop

reboot
