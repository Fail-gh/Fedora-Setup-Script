#!/bin/bash

dnf-install () {
	sudo dnf install -y $1 $2

	while [ $? -ne 0 ]
	do
		echo -e "\n\nRetrying in 5 seconds...\n\n"
		sleep 5
		sudo dnf install -y $1 $2
	done
}

dnf-swap () {
	sudo dnf swap -y $1 $2

	while [ $? -ne 0 ]
	do
		echo -e "\n\nRetrying in 5 seconds...\n\n"
		sleep 5
		sudo dnf swap -y $1 $2
	done
}

dnf-upgrade () {
	sudo dnf upgrade -y $1 $2 $3

	while [ $? -ne 0 ]
	do
		echo -e "\n\nRetrying in 5 seconds...\n\n"
		sleep 5
		sudo dnf upgrade -y $1 $2 $3
	done
}

flatpak-install () {
	sudo flatpak install -y $1

	while [ $? -ne 0 ]
	do
		echo -e "\n\nRetrying in 5 seconds...\n\n"
		sleep 5
		sudo flatpak install -y $1
	done
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
sudo systemctl enable --now snapper-boot.timer
sudo systemctl enable snapper-cleanup.timer

# Install SELinux Troubleshooter to analyze and resolve AVC denials
dnf-install "setroubleshoot"

# Enable Fedora Third-Party Repositories
sudo fedora-third-party enable

# Disable redundant and unnecessary repositories
sudo dnf copr disable copr.fedorainfracloud.org/phracek/PyCharm
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

# Clear dnf cache
dnf clean all
sudo dnf clean all

# Install Extension Manager, Flatseal and Gear Lever using Flatpak
flatpak-install "com.mattjakeman.ExtensionManager it.mijorus.gearlever com.github.tchx84.Flatseal"

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
