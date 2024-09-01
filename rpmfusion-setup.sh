#!/bin/sudo bash

#Install BTRFS Assistant
dnf install btrfs-assistant -y

#Execute btrfs_maintenance_configuration
./btrfs-maintenance-configuration.sh

#Adding RPMFusion repos
dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y

#Enablig OpenH264 for RPM Fusion
dnf config-manager --enable fedora-cisco-openh264 -y

#Enable users to install packages using Gnome Software or similar (Only GUI packages)
dnf update @core -y

#Switch to full ffpmeg
dnf swap ffmpeg-free ffmpeg --allowerasing -y

#Allows the application using the gstreamer framework and other multimedia software, to play others restricted codecs
dnf install @multimedia -y
dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
dnf update @sound-and-video -y

#Install Hardware Accelerated Codec for Intel
dnf install intel-media-driver libva-intel-driver -y

#Install mesa Hardware Accelerated Codec
dnf swap mesa-va-drivers mesa-va-drivers-freeworld -y
dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld -y
dnf swap mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686 -y
dnf swap mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686 -y

#Install RPMFusion Free Tainted repo
dnf install rpmfusion-free-release-tainted -y
dnf install libdvdcss -y

#Install RPMFusion NonFree Tainted repo
dnf install rpmfusion-nonfree-release-tainted -y
dnf --repo=rpmfusion-nonfree-tainted install "*-firmware" -y || dnf install "*-firmware"

#Install Hardware Accelerated Codec for GPU
nvidia=$(lspci | grep NVIDIA)
if [ -n "$nvidia" ]
then
	dnf install libva-nvidia-driver.{i686,x86_64} akmod-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-power vulkan xorg-x11-drv-nvidia-cuda-libs nvidia-vaapi-driver libva-utils vdpauinfo -y

	grubby --update-kernel=ALL --args='nvidia-drm.modeset=1'
fi

#Check Secure Boot state and select next part of the script
secure_boot=$(mokutil --sb-state | cut -d' ' -f2)
reboot=$(systemd-inhibit | grep akmods)
if [ -n "$nvidia" ]
then
	if [ $secure_boot == "enabled" ]
	then
		echo "[Desktop Entry]
Name=Nvidia Secure Boot
Exec=/usr/nvidia-secure-boot.sh
Terminal=true
Type=Application" > /home/$SUDO_USER/.config/autostart/nvidia-secure-boot.desktop
	elif [ $secure_boot == "disabled" ]
	then
		echo "[Desktop Entry]
Name=User Configuration
Exec=/usr/user-configuration.sh
Terminal=true
Type=Application" > /home/$SUDO_USER/.config/autostart/user-configuration.desktop
	fi
	echo "Installing NVIDIA kernel modules"
	while [ -n "$reboot" ]
	do
		reboot=$(systemd-inhibit | grep akmods)
	done
	reboot
else
	echo "[Desktop Entry]
Name=User Configuration
Exec=/usr/user-configuration.sh
Terminal=true
Type=Application" > /home/$SUDO_USER/.config/autostart/user-configuration.desktop
	reboot
fi