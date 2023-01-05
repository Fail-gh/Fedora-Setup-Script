#!/bin/bash
sudo awk '{sub("env_reset","   env_reset,pwfeedback",$2);print}' /etc/sudoers > sudo
sudo cp sudo /etc/sudoers
sudo rm /etc/yum.repos.d/_copr_phracek-PyCharm.repo /etc/yum.repos.d/rpmfusion-nonfree-nvidia-driver.repo /etc/yum.repos.d/rpmfusion-nonfree-steam.repo
sudo flatpak remote-delete flathub
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak install flathub com.mattjakeman.ExtensionManager -y

sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
sudo dnf groupupdate core -y
sudo dnf groupupdate multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
sudo dnf groupupdate sound-and-video -y
sudo dnf install rpmfusion-free-release-tainted -y
sudo dnf install libdvdcss -y
sudo dnf install rpmfusion-nonfree-release-tainted -y
sudo dnf --repo=rpmfusion-nonfree-tainted install "*-firmware" -y
sudo dnf update -y
sudo dnf install gnome-tweaks -y
sudo dnf install menulibre -y
sudo dnf install timeshift -y
sudo dnf remove fedora-bookmarks -y
gsettings set org.gnome.shell.window-switcher current-workspace-only false
gsettings set org.gnome.desktop.interface font-antialiasing rgba
gsettings set org.gnome.desktop.wm.preferences button-layout appmenu:minimize,maximize,close
gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"
gsettings set org.gnome.software packaging-format-preference "['RPM', 'flatpak']"
sudo timeshift --btrfs
sudo sed -i 's/"schedule_boot" : "false",/"schedule_boot" : "true",/g' /etc/timeshift/timeshift.json
sudo sed -i 's/"count_boot" : "5",/"count_boot" : "2",/g' /etc/timeshift/timeshift.json

sudo cp td.sh /usr/share/
sudo chmod +x /usr/share/td.sh
sudo cp oem.sh /usr/share/
sudo chmod +x /usr/share/oem.sh

cpu=$(cat /proc/cpuinfo | grep vendor | cut -d':' -f2 | cut -d' ' -f2 | grep -m1 "")
case $cpu in
	GenuineIntel)
                family=$(cat /proc/cpuinfo | grep family | cut -d':' -f2 | cut -d' ' -f2 | grep -m1 "")
                if [ $family -gt 4 ];
                then
                    	sudo dnf install intel-media-driver -y
                else
                    	sudo dnf install libva-intel-driver -y
                fi;;
        AuthenticAMD)
                sudo dnf swap mesa-va-drivers mesa-va-drivers-freeworld -y
                sudo dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld -y;;
esac

nvidia=$(lspci | grep NVIDIA)
if [ -z "$nvidia" ]
then
	gpu=0
else 
	sudo dnf install nvidia-vaapi-driver akmod-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-power vulkan xorg-x11-drv-nvidia-cuda-libs vdpauinfo libva-vdpau-driver libva-utils -y
	gpu=1
fi

if [ $gpu == "1" ]
then
	sb=$(mokutil --sb-state | cut -d' ' -f2)
	if [ $sb == "enabled" ]
	then
		sudo cp nsb.sh /usr/share/
		sudo sh -c "echo '[Desktop Entry]
Name=NvidiaSecureBoot
GenericName=Setup NVIDIA for secure boot
Exec=/usr/share/nsb.sh
Terminal=true
Type=Application
X-GNOME-Autostart-enabled=true' > /etc/xdg/autostart/nsb.desktop"
		sudo chmod +x /usr/share/nsb.sh
		reboot
	fi
else
        sudo sh -c "echo '[Desktop Entry]
Name=TPMDecryption
GenericName=Setup tpm decryption
Exec=/usr/share/td.sh
Terminal=true
Type=Application
X-GNOME-Autostart-enabled=true' > /etc/xdg/autostart/td.desktop"
        reboot
fi
