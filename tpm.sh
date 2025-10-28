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
		select tpm_decryption in Yes No
		do
			case $tpm_decryption in
				Yes)
					# List all LUKS encrypted devices
					encrypted_disk=$(sudo blkid -t TYPE=crypto_LUKS -o device)

					# Enroll each partition with TPM
					for encrypted_partition in $encrypted_disk
					do
						sudo systemd-cryptenroll --tpm2-device auto --tpm2-pcrs "2+5" $encrypted_partition
					done

					# Update /etc/crypttab for TPM decryption
					sudo sed -i 's/$/,tpm2-device=auto,tpm2-pcrs=2+5' /etc/crypttab
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
