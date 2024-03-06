#!/bin/sudo bash

#Add feedback when writing sudo password
awk '{sub("env_reset","   env_reset,pwfeedback",$2);print}' /etc/sudoers > sudo
cp sudo /etc/sudoers
rm sudo

#Remove useless repos
rm /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:phracek:PyCharm.repo /etc/yum.repos.d/rpmfusion-nonfree-nvidia-driver.repo /etc/yum.repos.d/rpmfusion-nonfree-steam.repo

#Create autostart folder as user
mkdir /home/$SUDO_USER/.config/autostart/
chown $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.config/autostart/

#Copy script to /usr
cp fedora-setup-upgraded.sh /usr
cp btrfs-maintenance-configuration.sh /usr
cp nvidia-secure-boot.sh /usr
cp user-configuration.sh /usr

chmod +x /usr/fedora-setup-upgraded.sh
chmod +x /usr/btrfs-maintenance-configuration.sh
chmod +x /usr/nvidia-secure-boot.sh
chmod +x /usr/user-configuration.sh

#Update system
dnf clean all
dnf check-update
while [[ $? = 100 || $? = 1 || $? = 3 || $? =  200 ]]
do
	dnf upgrade -y
done
	echo "[Desktop Entry]
Name=Fedora Setup Upgraded
Exec=/usr/fedora-setup-upgraded.sh
Terminal=true
Type=Application" > /home/$SUDO_USER/.config/autostart/fedora-setup-upgraded.desktop
reboot