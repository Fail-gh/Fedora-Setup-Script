#!/bin/bash

#Set current folder to autostart
sed -i "s|HOME|$PWD|g" "./autostart/fedora-setup.desktop"
sed -i "s|HOME|$PWD|g" "./autostart/rpmfusion-setup"
sed -i "s|HOME|$PWD|g" "./autostart/nvidia-secure-boot"
sed -i "s|HOME|$PWD|g" "./autostart/user-configuration"

#Create autostart folder as user
mkdir -p $HOME/.config/autostart

cp ./autostart/* $HOME/.config/autostart/

#Garant execution permission to all scripts
chmod +x ./rpmfusion-setup.sh
chmod +x ./btrfs-maintenance-configuration.sh
chmod +x ./nvidia-secure-boot.sh
chmod +x ./user-configuration.sh

#Update system
dnf clean all
pkcon refresh force
while [ $? != 0 ]
do
	echo -e "\nRetrying in 5 seconds...\n"
	sleep 5
	pkcon refresh force
done
pkcon update --only-download
while [[ $? != 0 && $? != 5 ]]
do
	echo -e "\nRetrying in 5 seconds...\n"
	sleep 5
	pkcon update --only-download
done
if [ $? == 0 ]
then
	pkcon offline-trigger
fi

rm $HOME/.config/autostart/fedora-setup.desktop
mv $HOME/.config/autostart/rpmfusion-setup $HOME/.config/autostart/rpmfusion-setup.desktop

reboot
