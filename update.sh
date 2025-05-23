#!/bin/bash

pkcon-manager () {
	pkcon $1

	while [[ $? -ne 0 && $? -ne 5 ]]
	do
		echo -e "\nRetrying in 5 seconds...\n"
		sleep 5
		$1
	done

	echo
}

# Set current folder to autostart
# Using "HOME" as a placeholder for replacement with the current working directory
for file in ./autostart/*
do
	sed -i "s|HOME|$PWD|g" "$file"
done

# Create autostart folder as user if it doesn't already exist
mkdir -p "$HOME/.config/autostart"

# Copy modified autostart files to the user's autostart directory
if [ "$XDG_SESSION_DESKTOP" == "gnome" ]
then
	cp ./autostart/gnome-* "$HOME/.config/autostart/"
else
	cp ./autostart/kde-* "$HOME/.config/autostart/"
fi

# Grant execution permission to all necessary setup scripts
chmod +x ./setup.sh
chmod +x ./tpm.sh

#Update system
pkcon-manager "refresh force"
pkcon-manager "update --only-download"

# Trigger an offline update for the next reboot
pkcon offline-trigger

if [ "$XDG_SESSION_DESKTOP" == "gnome" ]
then
	rm "$HOME/.config/autostart/gnome-update.desktop"
	mv "$HOME/.config/autostart/gnome-setup" "$HOME/.config/autostart/gnome-setup.desktop"
else
	rm "$HOME/.config/autostart/kde-update.desktop"
	mv "$HOME/.config/autostart/kde-setup.bak" "$HOME/.config/autostart/kde-setup.desktop"
fi

# Reboot the system
reboot
