#!/bin/bash
sudo mokutil --timeout 10
tpm=$(systemd-cryptenroll --tpm2-device=list | grep tpm)
oem=$(whoami)
if [ -z "$tpm" ]
then
	echo "No TPM available, Skipping..."
else
if [ $oem == "oem" ]
then
	tpmd=1
fi
	PS3="-> "
	echo "Enable tpm decryption? (Auto unlock of disk/s at boot, but is less secure)"
	select tpmd in Yes No; do
		case $tpmd in
			Yes)
				lsblk -ro name,type,fsroots | grep -v disk | grep -v NAME | grep -v / | cut -d' ' -f1 | grep -m3 "" > crypted
				max=$(wc -l crypted | cut -d' ' -f1)
				n=1
				while [ $n -le $max ]
				do
					part=$(sed -n ''$n'p' crypted)
					((n++))
					sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=4+7 /dev/$part
				done
				sudo awk '{sub("none","-",$3);print}' /etc/crypttab > crypttab && sudo awk '{sub("discard","tpm2-device=auto,discard",$4);print}' crypttab > crypttab2
				sudo cp crypttab2 /etc/crypttab
				sudo rm crypted
				sudo rm crypttab
				sudo rm crypttab2
				echo "Please wait..."
				sudo grubby --args="rd.luks.options=tpm2-device=auto" --update-kernel=ALL
				sudo dracut -f
				break;;
		    	No)
				break;;
		    	*)
				echo "Invalid option";;
		 esac
	done
fi

if [ $oem == "oem" ]
then
	sudo sh -c "echo '[Desktop Entry]
Name=OEMSetup
GenericName=First run setup
Exec=/usr/share/oem.sh
Terminal=true
Type=Application
X-GNOME-Autostart-enabled=true' > /etc/xdg/autostart/oem.desktop"
	sudo rm /etc/NetworkManager/system-connections/*
	sudo rm /etc/xdg/autostart/td.desktop
	sudo rm /usr/share/td.sh
	sudo userdel -rf oem
	gnome-session-quit --force
else
	sudo rm /etc/xdg/autostart/td.desktop
	sudo rm /usr/share/td.sh
	reboot
fi
