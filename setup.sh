#!/bin/bash

dnf-install () {
	sudo dnf install -y $1 $2

	while [ $? -ne 0 ]
	do
		echo -e "\nRetrying in 5 seconds...\n"
		sleep 5
		sudo dnf install -y $1 $2
	done

	echo
}

dnf-swap () {
	sudo dnf swap -y $1 $2

	while [ $? -ne 0 ]
	do
		echo -e "\nRetrying in 5 seconds...\n"
		sleep 5
		sudo dnf swap -y $1 $2
	done

	echo
}

dnf-upgrade () {
	sudo dnf upgrade -y $1 $2 $3

	while [ $? -ne 0 ]
	do
		echo -e "\nRetrying in 5 seconds...\n"
		sleep 5
		sudo dnf upgrade -y $1 $2 $3
	done

	echo
}

flatpak-install () {
	flatpak install -y $1

	while [ $? -ne 0 ]
	do
		echo -e "\nRetrying in 5 seconds...\n"
		sleep 5
		flatpak install -y $1
	done

	echo
}

dnf-remove () {
	sudo dnf remove -y $1

	while [ $? -ne 0 ]
	do
		echo -e "\nRetrying in 5 seconds...\n"
		sleep 5
		sudo dnf remove -y $1
	done

	echo -en "\n"
}

# Install BTRFS Assistant for GUI BTRFS management
dnf-install "btrfs-assistant"

# Auto BTRFS maintenance configuration
sudo sed -i 's|BTRFS_BALANCE_MOUNTPOINTS="/"|BTRFS_BALANCE_MOUNTPOINTS="/:/home"|g' "/etc/sysconfig/btrfsmaintenance"
sudo sed -i 's|BTRFS_SCRUB_MOUNTPOINTS="/"|BTRFS_SCRUB_MOUNTPOINTS="/:/home"|g' "/etc/sysconfig/btrfsmaintenance"

# Configure snapshot of root
sudo snapper create-config /
sudo snapper set-config NUMBER_LIMIT=5 TIMELINE_CREATE=no

# Enable snapper timers
sudo systemctl disable snapper-timeline.timer
echo
sudo systemctl enable --now snapper-boot.timer
echo
sudo systemctl enable snapper-cleanup.timer
echo

# Install SELinux Troubleshooter to analyze and resolve AVC denials
dnf-install "setroubleshoot"

# Enable Fedora Third-Party Repositories
sudo fedora-third-party enable

# Disable redundant and unnecessary repositories
sudo dnf copr disable copr.fedorainfracloud.org/phracek/PyCharm
echo
sudo sed -i 's|enabled=1|enabled=0|g' "/etc/yum.repos.d/rpmfusion-nonfree-steam.repo"
sudo sed -i 's|enabled=1|enabled=0|g' "/etc/yum.repos.d/rpmfusion-nonfree-nvidia-driver.repo"

# Disable Fedora Flatpaks
sudo flatpak remote-modify --disable fedora

# Add RPMFusion repositories
dnf-install "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

# Enable users to install packages using Gnome Software or similar (Only GUI packages)
dnf-upgrade "@core"

# Allows the application using the gstreamer framework and other multimedia software, to play others restricted codecs
dnf-upgrade "--setopt=install_weak_deps=False" "--exclude=PackageKit-gstreamer-plugin" "@multimedia"

# Install Hardware Accelerated Codec for Intel (Use libva-intel-driver for Haswell, 4 gen, 2013 or older)
dnf-install "intel-media-driver"

# Install RPMOther exit codes could be returned by the specific command itself, see its documentation for Fusion Free Tainted repo
dnf-install "rpmfusion-free-release-tainted"
dnf-install "libdvdcss"

# Install RPMFusion NonFree Tainted repo
dnf-install "rpmfusion-nonfree-release-tainted"
dnf-install "--repo=rpmfusion-nonfree-tainted" "*-firmware"

# NVIDIA driver installation if NVIDIA hardware is detected
nvidia=$(lspci | grep NVIDIA)

if [ -n "$nvidia" ]
then
	dnf-install "akmod-nvidia xorg-x11-drv-nvidia-cuda libva-nvidia-driver.i686 libva-nvidia-driver.x86_64"
fi

# Switch to full ffpmeg
dnf-swap "--allowerasing" "ffmpeg-free ffmpeg"

# Install mesa Hardware Accelerated Codec
dnf-swap "mesa-va-drivers mesa-va-drivers-freeworld"
dnf-swap "mesa-vdpau-drivers mesa-vdpau-drivers-freeworld"
dnf-swap "mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686"
dnf-swap "mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686"

# Replace Rhythmbox with GNOME default apps
dnf-remove "rhythmbox"
dnf-install "decibels gnome-music"

# Install AppIndicator and KStatusNotifierItem Support
dnf-install "gnome-shell-extension-appindicator"

# Replace RPMs with Flatpaks
dnf-remove "mediawriter gnome-boxes @libreoffice firefox"
rm -r $HOME/.mozilla
flatpak-install "org.fedoraproject.MediaWriter org.gnome.Boxes org.libreoffice.LibreOffice org.mozilla.firefox"

# Install Extension Manager, Flatseal and Gear Lever using Flatpak
flatpak-install "com.mattjakeman.ExtensionManager it.mijorus.gearlever com.github.tchx84.Flatseal"

# Clear dnf cache
dnf clean all
echo
sudo dnf clean all
echo

# Move Btrfs Assistant and SELinux Troubleshooter to "System" folder
gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/System/ apps "['org.gnome.baobab.desktop', 'org.gnome.DiskUtility.desktop', 'org.gnome.Logs.desktop', 'org.freedesktop.MalcontentControl.desktop', 'org.freedesktop.GnomeAbrt.desktop', 'org.gnome.SystemMonitor.desktop', 'btrfs-assistant.desktop', 'setroubleshoot.desktop']"

# Move Charachter to "Utilities" folder
gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Utilities/ apps "['org.gnome.Connections.desktop', 'org.gnome.Evince.desktop', 'org.gnome.font-viewer.desktop', 'org.gnome.Loupe.desktop', 'org.gnome.Characters.desktop']"

# Remove RPMFusion setup from autostart
rm "$PWD/.config/autostart/setup.desktop"

if [ -n "$nvidia" ]
then
	# Wait for NVIDIA driver to load if present
	reboot=$(systemd-inhibit | grep akmods)

	while [ -n "$reboot" ]
	do
		sleep 1
		reboot=$(systemd-inhibit | grep akmods)
	done
fi

mv "$PWD/.config/autostart/tpm" "$PWD/.config/autostart/tpm.desktop"

# Final reboot
reboot
