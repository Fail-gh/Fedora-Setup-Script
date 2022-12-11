#!/bin/bash
echo "Enter disk encryption key(Minimum 8 characters):"
sudo cryptsetup luksChangeKey /dev/sda3

echo "Setup tpm decryption? (Auto unlock of disk/s, but is less secure)"
	select tpmd in Yes No; do
	case $tpmd in
		Yes)
			sudo systemd-cryptenroll /dev/nvme0n1p3 --wipe-slot=tpm2
			sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/sda3
			break;;
    	No)
			break;;
    	*)
			echo "Invalid option";;
  	esac
	done

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
