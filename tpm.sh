#!/bin/bash

dnf-manager () {
	sudo dnf -y "$@"
	local exit_code=$?

	while [ $exit_code -ne 0 ]
	do
		echo -e "\nRetrying in 5 seconds...\n"
		sleep 5
		sudo dnf -y "$@"
		exit_code=$?
	done

	echo
}

if [ "$XDG_SESSION_DESKTOP" == "gnome" ]
then
	# Enable AppIndicator and KStatusNotifierItem Support
	gnome-extensions enable appindicatorsupport@rgcjonas.gmail.com
fi

# Check if LUKS encrypted partitions and TPM are available
luks=$(lsblk | grep luks)
tpm=$(systemd-cryptenroll --tpm2-device=list | grep tpm)

if [ -n "$luks" ]
then
	if [ -n "$tpm" ]
	then
		PS3="-> "
		echo "Enable tpm decryption? (Auto unlock disk at boot, but is less secure)"
		select tpmd in Yes No
		do
			case $tpmd in
				Yes)
					# Install Clevis
					dnf-manager install clevis clevis-luks clevis-dracut clevis-udisks2 clevis-systemd

					# List LUKS encrypted device
					uuid=$(sudo blkid | grep fedora | sed -n 's/.*luks-\([^ ]*\).*/\1/p' | cut -d':' -f1)
					crypted=$(sudo blkid -t UUID=$uuid | cut -d':' -f1 | cut -d'/' -f3)

					# Configure clevis
					sudo clevis luks bind -d /dev/$crypted tpm2 '{"pcr_ids":"2,5"}'

					sudo mkdir /etc/systemd/system/systemd-ask-password-plymouth.service.d
					echo "[Service]" | sudo tee /etc/systemd/system/systemd-ask-password-plymouth.service.d/override.conf > /dev/null
					echo "ExecStartPre=/bin/sleep 10" | sudo tee -a /etc/systemd/system/systemd-ask-password-plymouth.service.d/override.conf > /dev/null
					echo 'install_items+=" /etc/systemd/system/systemd-ask-password-plymouth.service.d/override.conf "' | sudo tee /etc/dracut.conf.d/systemd-ask-password-plymouth.conf > /dev/null

					# Update initramfs
					sudo dracut -fv --regenerate-all
					break;;
				No)
					break;;
				*)
					echo "Invalid option. Please choose Yes or No."
					break;;
			esac
		done
	else
		echo "TPM not available."
	fi
else
	echo "No encrypted disk found."
fi

# Remove tpm configuration from autostart
if [ "$XDG_SESSION_DESKTOP" == "gnome" ]
then
	rm $HOME/.config/autostart/gnome-tpm.desktop
else
	rm $HOME/.config/autostart/kde-tpm.desktop
fi
