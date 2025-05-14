#!/bin/bash

dnf-manager () {
	sudo dnf $1 -y $2 $3 $4

	while [ $? -ne 0 ]
	do
		echo -e "\nRetrying in 5 seconds...\n"
		sleep 5
		sudo dnf $1 -y $2 $3 $4
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

# Enable Fedora Third-Party Repositories
sudo fedora-third-party enable

# Disable Fedora Flatpaks
sudo flatpak remote-modify --disable fedora

# Disable redundant and unnecessary repositories
sudo dnf copr disable copr.fedorainfracloud.org/phracek/PyCharm
echo
sudo sed -i 's|enabled=1|enabled=0|g' "/etc/yum.repos.d/rpmfusion-nonfree-steam.repo"
sudo sed -i 's|enabled=1|enabled=0|g' "/etc/yum.repos.d/rpmfusion-nonfree-nvidia-driver.repo"

# Install BTRFS Assistant for GUI BTRFS management
dnf-manager "install" "btrfs-assistant"

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
dnf-manager "install" "setroubleshoot"

# Add RPMFusion repositories
dnf-manager "install" "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

# Enable users to install packages using Gnome Software or similar (Only GUI packages)
dnf-manager "upgrade" "@core"

# Allows the application using the gstreamer framework and other multimedia software, to play others restricted codecs
dnf-manager "upgrade" "--setopt=install_weak_deps=False" "--exclude=PackageKit-gstreamer-plugin" "@multimedia"

# Install Hardware Accelerated Codec for Intel (Use libva-intel-driver for Haswell, 4 gen, 2013 or older)
dnf-manager "install" "intel-media-driver"

# Install RPMOther exit codes could be returned by the specific command itself, see its documentation for Fusion Free Tainted repo
dnf-manager "install" "rpmfusion-free-release-tainted"
dnf-manager "install" "libdvdcss"

# Install RPMFusion NonFree Tainted repo
dnf-manager "install" "rpmfusion-nonfree-release-tainted"
dnf-manager "install" "--repo=rpmfusion-nonfree-tainted" "*-firmware"

# NVIDIA driver installation if NVIDIA hardware is detected
nvidia=$(lspci | grep NVIDIA)

if [ -n "$nvidia" ]
then
	dnf-manager "install" "akmod-nvidia xorg-x11-drv-nvidia-cuda libva-nvidia-driver.i686 libva-nvidia-driver.x86_64"
fi

# Install compute runtime if intel gpu is detected
intel_cpu=$(lscpu | grep Intel)
intel_gpu=$(lspci | grep VGA | grep Intel)

if [[ -n "$intel_cpu" || -n "$intel_gpu" ]]
then
	dnf-manager "install" "intel-compute-runtime"
fi

# Install ROCm runtime if AMD gpu is detected
amd_gpu=$(lspci | grep VGA | grep AMD)

if [ -n "$amd_gpu" ]
then
	dnf-manager "install" "rocm-opencl rocm-hip rocm-core"
fi

# Switch to full ffpmeg
dnf-manager "swap" "--allowerasing" "ffmpeg-free ffmpeg"

# Install mesa Hardware Accelerated Codec
dnf-manager "swap" "mesa-va-drivers mesa-va-drivers-freeworld"
dnf-manager "swap" "mesa-vdpau-drivers mesa-vdpau-drivers-freeworld"
dnf-manager "swap" "mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686"
dnf-manager "swap" "mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686"

if [ "$XDG_SESSION_DESKTOP" == "gnome" ]
then
	# Replace Rhythmbox with GNOME default apps
	dnf-manager "remove" "rhythmbox"
	dnf-manager "install" "decibels gnome-music"

	# Install AppIndicator and KStatusNotifierItem Support
	dnf-manager "install" "gnome-shell-extension-appindicator"

	# Replace GNOME Boxes RPM with Flatpak
	dnf-manager "remove" "gnome-boxes"
	flatpak-install "org.gnome.Boxes"
fi

# Replace RPMs with Flatpaks
dnf-manager "remove" "mediawriter @libreoffice firefox"
rm -r $HOME/.mozilla
flatpak-install "org.fedoraproject.MediaWriter org.libreoffice.LibreOffice org.mozilla.firefox"

if [ "$XDG_SESSION_DESKTOP" == "gnome" ]
then
# Install Extension Manager, Flatseal and Gear Lever using Flatpak
flatpak-install "com.mattjakeman.ExtensionManager it.mijorus.gearlever com.github.tchx84.Flatseal"
fi

# Clear dnf cache
dnf clean all
echo
sudo dnf clean all
echo

if [ "$XDG_SESSION_DESKTOP" == "gnome" ]
then
# Move Btrfs Assistant and SELinux Troubleshooter to "System" folder
gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/System/ apps "['btrfs-assistant.desktop', 'org.gnome.baobab.desktop', 'org.gnome.DiskUtility.desktop', 'org.gnome.Logs.desktop', 'org.freedesktop.MalcontentControl.desktop', 'org.freedesktop.GnomeAbrt.desktop', 'setroubleshoot.desktop', 'org.gnome.SystemMonitor.desktop']"

# Move Charachter to "Utilities" folder
gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/Utilities/ apps "['org.gnome.Characters.desktop', 'org.gnome.Connections.desktop', 'org.gnome.Evince.desktop', 'org.gnome.font-viewer.desktop', 'org.gnome.Loupe.desktop']"
fi

# Remove RPMFusion setup from autostart
if [ "$XDG_SESSION_DESKTOP" == "gnome" ]
then
	rm "$PWD/.config/autostart/gnome-setup.desktop"
else
	rm "$PWD/.config/autostart/plasma-setup.desktop"
fi

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

if [ "$XDG_SESSION_DESKTOP" == "gnome" ]
then
	mv "$PWD/.config/autostart/gnome-tpm" "$PWD/.config/autostart/gnome-tpm.desktop"
else
	mv "$PWD/.config/autostart/plasma-tpm.bak" "$PWD/.config/autostart/plasma-tpm.desktop"
fi

# Final reboot
reboot
