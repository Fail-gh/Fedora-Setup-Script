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

flatpak-install () {
	flatpak install -y "$@"
	local exit_code=$?

	while [ $exit_code -ne 0 ]
	do
		echo -e "\nRetrying in 5 seconds...\n"
		sleep 5
		flatpak install -y "$@"
		exit_code=$?
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

# Add RPMFusion repositories
dnf-manager install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Enable openH264 repository
sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1

# Enable users to install packages using Gnome Software or similar (Only GUI packages)
dnf-manager install rpmfusion-\*-appstream-data

# Switch to full ffpmeg
dnf-manager swap --allowerasing ffmpeg-free ffmpeg

# Allows the application using the gstreamer framework and other multimedia software, to play others restricted codecs
dnf-manager upgrade --setopt=install_weak_deps=False --exclude=PackageKit-gstreamer-plugin @multimedia

# Install RPMFusion Free Tainted repo
dnf-manager install rpmfusion-free-release-tainted
dnf-manager install libdvdcss

# Install RPMFusion NonFree Tainted repo
dnf-manager install rpmfusion-nonfree-release-tainted

# NVIDIA driver installation if NVIDIA hardware is detected
nvidia=$(lspci | grep NVIDIA)

if [ -n "$nvidia" ]
then
	dnf-manager install akmod-nvidia xorg-x11-drv-nvidia-cuda libva-nvidia-driver.i686 libva-nvidia-driver.x86_64
fi

intel_gpu=$(lspci | grep VGA | grep Intel)

if [[ -n "$intel_gpu" ]]
then
	# Install Hardware Accelerated Codec for Intel (Use libva-intel-driver for Haswell, 4 gen, 2013 or older)
	dnf-manager install intel-media-driver

	# Install Intel runtime for oneAPI Level Zero and OpenCL (Use mesa-libOpenCL if your hardware is not supported: https://github.com/intel/compute-runtime#supported-platforms)
	dnf-manager install intel-compute-runtime
fi

amd_gpu=$(lspci | grep VGA | grep AMD)

if [ -n "$amd_gpu" ]
then
	# Install mesa Hardware Accelerated Codec
	dnf-manager install mesa-va-drivers-freeworld
	dnf-manager install mesa-va-drivers-freeworld.i686

	# Install ROCm runtime (Use mesa-libOpenCL if your hardware is not supported: https://fedoraproject.org/wiki/SIGs/HC#HW_Support)
	dnf-manager install rocm-hip rocm-opencl
fi

if [ "$XDG_SESSION_DESKTOP" == "gnome" ]
then
	# Install AppIndicator and KStatusNotifierItem Support
	dnf-manager install gnome-shell-extension-appindicator

	# Install Extension Manager, Flatseal and Gear Lever using Flatpak
	flatpak-install com.mattjakeman.ExtensionManager
fi

# Remove RPMFusion setup from autostart
if [ "$XDG_SESSION_DESKTOP" == "gnome" ]
then
	rm "$HOME/.config/autostart/gnome-setup.desktop"
else
	rm "$HOME/.config/autostart/kde-setup.desktop"
fi

if [ -n "$nvidia" ]
then
	# Wait for NVIDIA driver to load
	reboot=$(systemd-inhibit | grep akmods)

	while [ -n "$reboot" ]
	do
		sleep 1
		reboot=$(systemd-inhibit | grep akmods)
	done
fi

if [ "$XDG_SESSION_DESKTOP" == "gnome" ]
then
	mv "$HOME/.config/autostart/gnome-tpm" "$HOME/.config/autostart/gnome-tpm.desktop"
else
	mv "$HOME/.config/autostart/kde-tpm.bak" "$HOME/.config/autostart/kde-tpm.desktop"
fi

# Final reboot
reboot
