#!/bin/bash

#Install, if on GNOME, Extension Manager, libadwaita theme GTK-3 flatpak apps and Gear Lever a tool to use appimage more easily
if [[ $XDG_CURRENT_DESKTOP = "GNOME" ]]
then
	sudo dnf install gnome-tweaks menulibre adw-gtk3-theme -y

	sudo flatpak install flathub com.mattjakeman.ExtensionManager it.mijorus.gearlever org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark com.github.tchx84.Flatseal -y
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
					max=$(wc -l crypted | cut -d' ' -f1)
					n=1
					while [ $n -le $max ]
					do
						part=$(sed -n ''$n'p' crypted)
						((n++))
						sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=2+5+6 /dev/$part
					done
					sudo awk '{sub("none","-",$3);print}' /etc/crypttab > crypttab
					sudo awk '{sub("discard","tpm2-device=auto,discard",$4);print}' crypttab > crypttab2
					sudo cp crypttab2 /etc/crypttab
					rm crypted
					rm crypttab
					rm crypttab2
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
	fi
else
	echo "No encrypted disk"
fi

sudo mokutil --timeout 10
sudo rm /home/$LOGNAME/.config/autostart/user_configuration.desktop
sudo rm /usr/fedora-setup-upgraded.sh
sudo rm /usr/btrfs-maintenance-configuration.sh
sudo rm /usr/nvidia-secure_boot.sh
sudo rm /usr/user-configuration.sh
reboot
