#!/bin/sudo bash

#Adding RPMFusion repos
dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y

#Enable users to install packages using Gnome Software (Only GUI packages)
dnf groupupdate core -y

#Switch to full ffpmeg
dnf swap ffmpeg-free ffmpeg --allowerasing -y

#Allows the application using the gstreamer framework and other multimedia software, to play others restricted codecs
dnf install gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel -y
dnf install lame\* --exclude=lame-devel -y
dnf group upgrade --with-optional Multimedia -y
dnf groupupdate multimedia --setop="install_weak_deps=False" -y
dnf groupupdate sound-and-video -y

#Install RPMFusion Free Tainted repo
dnf install rpmfusion-free-release-tainted -y
dnf install libdvdcss -y

#Install RPMFusion NonFree Tainted repo
dnf install rpmfusion-nonfree-release-tainted -y
dnf install "*-firmware" -y

#Install BTRFS Assistant
dnf install btrfs-assistant -y

#Execute btrfs_maintenance_configuration
chmod +x btrfs_maintenance_configuration.sh
./btrfs_maintenance_configuration.sh

#Install mesa Hardware Accelerated Codec
dnf swap mesa-va-drivers mesa-va-drivers-freeworld -y
dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld -y
dnf swap mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686 -y
dnf swap mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686 -y

#Install Hardware Accelerated Codec for Intel
cpu=$(cat /proc/cpuinfo | grep vendor | cut -d':' -f2 | cut -d' ' -f2 | grep -m1 "")
if [ $cpu = "GenuineIntel" ]
then
	family=$(cat /proc/cpuinfo | grep "model name" | cut -d':' -f2 | cut -d' ' -f4 | cut -d'-' -f2 | grep -m1 "" | head | grep -Eo '[0-9]{1,256}')
        if [ $family -gt 4000 ]
        then
            	dnf install intel-media-driver -y
        else
            	dnf install libva-intel-driver -y
        fi	
fi

#Install Hardware Accelerated Codec for GPU
nvidia=$(lspci | grep NVIDIA)
if [ -n "$nvidia" ]
then
	dnf install xorg-x11-drv-nvidia-libs.i686 libva-nvidia-driver.i686 -y
	dnf install libva-nvidia-driver.x86_64 akmod-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-power vulkan xorg-x11-drv-nvidia-cuda-libs vdpauinfo libva-utils -y
	grubby --update-kernel=ALL --args='nvidia-drm.modeset=1'
fi

#Copy next part of the script in /usr
cp user_configuration.sh /usr
chmod +x /usr/user_configuration.sh

rm /usr/fedora-setup-upgraded.sh
rm /home/$USERNAME/.config/autostart/fedora-setup-upgraded.desktop

#Check Secure Boot state and select next part of the script
if [ -n "$nvidia" ]
then
	secure_boot=$(mokutil --sb-state | cut -d' ' -f2)
	if [ $secure_boot == "enabled" ]
	then
		cp nvidia_secure_boot.sh /usr
		echo "[Desktop Entry]
Name=Nvidia Secure Boot
Exec=/usr/nvidia_secure_boot.sh
Terminal=true
Type=Application
X-GNOME-Autostart-enabled=true" > /home/$USERNAME/.config/autostart/nvidia_secure_boot.desktop
		chmod +x /usr/nvidia_secure_boot.sh
		reboot=$(systemd-inhibit | grep akmods)
		echo "Installing NVIDIA kernel modules"
		while [ -n "$reboot" ]
		do
		    reboot=$(systemd-inhibit | grep akmods)
		done
		reboot
	fi
else
	echo "[Desktop Entry]
Name=User Configuration
Exec=/usr/user_configuration.sh
Terminal=true
Type=Application
X-GNOME-Autostart-enabled=true" > /home/$USERNAME/.config/autostart/user_configuration.desktop
	reboot
fi
