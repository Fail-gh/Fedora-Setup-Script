#!/bin/bash

pkcon-update () {
	$1

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
cp ./autostart/* "$HOME/.config/autostart/"

# Grant execution permission to all necessary setup scripts
chmod +x ./setup.sh
chmod +x ./tpm.sh

#Update system
pkcon-update "pkcon refresh force"
pkcon-update "pkcon update --only-download"

# If the update was successful, trigger an offline update for the next reboot
if [ $? -eq 0 ]
then
	pkcon offline-trigger
fi

rm "$HOME/.config/autostart/update.desktop"
mv "$HOME/.config/autostart/setup" "$HOME/.config/autostart/setup.desktop"

# Reboot the system
reboot
