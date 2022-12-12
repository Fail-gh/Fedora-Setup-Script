#!/bin/bash
echo "Select CPU:"
PS3="-> "
select cpu in "Intel newer than 4 gen (Ex. <=5 gen)" AMD "Intel older than 5 gen (Ex. >=4 gen)"; do
	case $cpu in
	"Intel newer than 4 gen (Ex. <=5 gen)")
		break;;
    AMD)
		break;;
    "Intel older than 5 gen (Ex. >=4 gen)")
		break;;
    *)
		echo "Invalid option";;
  esac
done

echo "Select GPU:"
select gpu in Nvidia Other; do
	case $gpu in
	Nvidia)
		break;;
    Other)
		break;;
    *)
		echo "Invalid option";;
  esac
done

sudo flatpak remote-delete flathub
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak install flathub com.mattjakeman.ExtensionManager -y

sudo dnf update -y
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
sudo dnf groupupdate core -y
sudo dnf groupupdate multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
sudo dnf groupupdate sound-and-video -y
sudo dnf install rpmfusion-free-release-tainted -y
sudo dnf install libdvdcss -y
sudo dnf install rpmfusion-nonfree-release-tainted -y
sudo dnf --repo=rpmfusion-nonfree-tainted install "*-firmware" -y
sudo rm /etc/yum.repos.d/_copr_phracek-PyCharm.repo /etc/yum.repos.d/google-chrome.repo /etc/yum.repos.d/rpmfusion-nonfree-nvidia-driver.repo /etc/yum.repos.d/rpmfusion-nonfree-steam.repo
sudo dnf install gnome-tweaks -y
sudo dnf install timeshift -y
sudo dnf remove fedora-bookmarks -y

case $cpu in
	"Intel newer than 4 gen (Ex. <=5 gen)")
		sudo dnf install intel-media-driver -y;;
	AMD)
		sudo dnf swap mesa-va-drivers mesa-va-drivers-freeworld -y
		sudo dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld -y;;
	"Intel older than 5 gen (Ex. >=4 gen)")
		sudo dnf install libva-intel-driver -y;;
esac

case $gpu in
	Nvidia)
		gnome-software --search="NVIDIA Linux Graphics Driver" &
		echo "Store opened, install nvidia driver"
		echo "Nvidia driver are installed?"
		select nvidia in Yes No; do
		case $nvidia in
			Yes)
				gnome-software --quit
				sudo dnf install nvidia-vaapi-driver -y
				break;;
    		No)
				echo "Install them and continue";;
    		*)
				echo "Invalid option";;
  		esac
		done
		nsb=1;;
	Other)
		nsb=0;;
	*)
		echo "invalid option";;
esac

if [ $nsb != "0" ]
then
	echo "Secure boot with Nvidia? "
	select sb in "Yes" "No"; do
		case $sb in
		"Yes")
			sudo /usr/sbin/kmodgenca -a
			echo "Insert user password"
			sudo mokutil --import /etc/pki/akmods/certs/public_key.der
			break;;
		"No")
			break;;
		*)
			echo "Invalid option";;
  	esac
	done
fi

echo "Setup tpm decryption?"
select tpmd in Yes No; do
	case $tpmd in
	Yes)
		sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/sda3
		cript=$(sudo cat /etc/crypttab | cut -d' ' -f1,2)
		sudo sh -c "echo $cript - tpm2-device=auto,discard > /etc/crypttab"
		sudo grubby --args="rd.luks.options=tpm2-device=auto" --update-kernel=ALL
		sudo dracut -f
		break;;
    No)
		break;;
    *)
		echo "Invalid option";;
  esac
done

echo "OEM Install?"
select oem in Yes No; do
	case $oem in
	Yes)	
		sudo cp runme.sh /usr/share/
		sudo sh -c "echo '[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=RunMe
Exec=/usr/share/runme.sh
Terminal=true' >> /usr/share/applications/runme.desktop"
		sudo chmod +x /usr/share/runme.sh
		sudo userdel -f oem
		break;;
    No)
		break;;
    *)
		echo "Invalid option";;
  esac
done

if [ $oem = 1 ] && [ $tpmd = 2 ]
then
	sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/sda3
	cript=$(sudo cat /etc/crypttab | cut -d' ' -f1,2)
	sudo sh -c "echo $cript - tpm2-device=auto,discard > /etc/crypttab"
	sudo grubby --args="rd.luks.options=tpm2-device=auto" --update-kernel=ALL
	sudo dracut -f
fi

echo "Reboot?"
select reboot in Yes No; do
	case $reboot in
	Yes)
		reboot
		break;;
    No)
		break;;
    *)
		echo "Invalid option";;
  esac
done
