# Fedora-Setup-Script
- [Introduction](#introduction)
- [Fresh Install](#freshinstall)
- [Coming from Windows](#comingfromwindows)
- [Known Issues](#knownissues)

## Fedora install guide and semi-automated post install script: <a name="introduction"></a>

## Fresh Install <a name="freshinstall"></a>

## Coming from Windows <a name="comingfromwindows"></a>

⚠️ **No dual boot** ⚠️

Guide:

1. Do all Windows updates including the optional ones

1. Check if BIOS/UEFI is up to date (_**It depends on your device's manufacturer**_)
1. (*Optional*) (*Raccomended*) Reset Factory default options in BIOS/UEFI
1. Enable virtualization and tpm (_**It depends on your device's manufacturer**_)
1. Enable secure boot and reset to default the secure boot key
1. Start [Fedora](https://getfedora.org/en/workstation/) from the USB
1. Open [Disks](https://wiki.gnome.org/Apps/Disks) app
1. Select the windows disk from the left then in the top right corner click on the 3 dots menu then Format Disks...

   ![Disks](https://github.com/Fail-gh/Fedora-Setup-Script/blob/main/Images/Disks.png?raw=true)
   
1. Select "Don't overwrite existing data (Quick)" and "No partitioning (Empty)"

   ![Disks](https://github.com/Fail-gh/Fedora-Setup-Script/blob/main/Images/Format%20Disks.png?raw=true)

1. Open or Select "Install to Hard Drive"
1. Select Language, Keyboard Layout and Time & Date
1. Go to "Installation Destination"
1. Select the previously prepared disk
1. Check Custom and Done
1. Check Encrypt my data (_**Raccomended**_)
1. And then "Click here to create them automatically"
1. Set home partition name to @home, then update settings
1. Set hroot partition name to @, then update settings
1. Click "Done" and insert the encryption passhphrase
1. "Save Passhphrase", accept changes and begin installation (Bottom right corner)
1. Click "Finish Installation" and Reboot
1. Enter BIOS/UEFI and set Fedora Disk as the first boot priority
1. Start Setup _**without**_ enabling Third-Party Repositories
1. Open terminal and write:
   ```
   sudo dnf install gnome-console -y && sudo dnf remove gnome-terminal -y && exit
   ```
1. When the terminal closes you will have a pure install of Fedora

1. Download the [script](https://github.com/Fail-gh/Fedora-Setup-Script/releases/download/Release/setup.sh) and put in the home directory
1. Open the console (ex terminal) and type:
   ```
   sudo chmod +x setup.sh
   ./setup.sh
   ```
1. Follow the instruction on screen

## Known Issues<a name="knownissues"></a>

1. Error with multiple disk attacched
