#!/bin/sudo bash

# Add feedback when entering the sudo password
if ! grep -q pwfeedback /etc/sudoers
then
	echo -e "\n# Enables visual feedback (displaying asterisks) when entering a password\nDefaults pwfeedback" >> /etc/sudoers
fi

# Install BTRFS Assistant
dnf install btrfs-assistant -y

# Auto BTRFS maintenance configuration
sed -i 's|BTRFS_BALANCE_MOUNTPOINTS="/"|BTRFS_BALANCE_MOUNTPOINTS="/:/home"|g' "/etc/sysconfig/btrfsmaintenance"
sed -i 's|BTRFS_SCRUB_MOUNTPOINTS="/"|BTRFS_SCRUB_MOUNTPOINTS="/:/home"|g' "/etc/sysconfig/btrfsmaintenance"

# Configure snapshot of home
snapper -c home create-config /home
snapper -c home set-config NUMBER_LIMIT=5 NUMBER_LIMIT_IMPORTANT=1 TIMELINE_CREATE=no

# Configure snapshot of root
snapper create-config /
snapper set-config NUMBER_LIMIT=5 NUMBER_LIMIT_IMPORTANT=1 TIMELINE_CREATE=no

# Enable and start timers
systemctl disable snapper-timeline.timer
systemctl enable --now snapper-boot.timer
systemctl enable --now snapper-cleanup.timer

# Add RPMFusion repositories
dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y

# Enable OpenH264 for RPM Fusion
dnf config-manager setopt fedora-cisco-openh264.enabled=1

# Enable users to install packages using Gnome Software or similar (Only GUI packages)
dnf4 update @core -y

# Switch to full ffpmeg
dnf swap ffmpeg-free ffmpeg --allowerasing -y

# Allows the application using the gstreamer framework and other multimedia software, to play others restricted codecs
dnf4 update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y

# Install Hardware Accelerated Codec for Intel (Use libva-intel-driver for Haswell, 4 gen, 2013 or older)
dnf install intel-media-driver -y

# Install mesa Hardware Accelerated Codec
dnf swap mesa-va-drivers mesa-va-drivers-freeworld -y
dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld -y
dnf swap mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686 -y
dnf swap mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686 -y

# Install RPMFusion Free Tainted repo
dnf install rpmfusion-free-release-tainted -y
dnf install libdvdcss -y

# Install RPMFusion NonFree Tainted repo
dnf install rpmfusion-nonfree-release-tainted -y
dnf --repo=rpmfusion-nonfree-tainted install "*-firmware" -y

# NVIDIA driver installation if NVIDIA hardware is detected
nvidia=$(lspci | grep NVIDIA)

if [ -n "$nvidia" ]
then
	dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda libva-nvidia-driver.{i686,x86_64} -y
fi

# Clear dnf cache
dnf clean all
dnf4 clean all

# Remove RPMFusion setup from autostart
rm "$PWD/.config/autostart/rpmfusion-setup.desktop"

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

mv "$PWD/.config/autostart/user-configuration" "$PWD/.config/autostart/user-configuration.desktop"

# Final reboot
reboot
