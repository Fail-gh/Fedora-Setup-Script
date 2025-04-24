# :inbox_tray: How do I use the script?

To get started, run the following commands in your terminal:

```bash
git clone https://github.com/Fail-gh/Fedora-Setup-Script.git
cd Fedora-Setup-Script
chmod +x update.sh
./update.sh
```

**Note**:  
After completing the setup, if you're using an Intel Haswell CPU (4th generation, released in 2013 or earlier), you need to swap the media driver to enable hardware video decoding:

```bash
sudo dnf swap intel-media-driver libva-intel-driver -y
```
This replaces the newer driver with one that is compatible with older hardware, enabling hardware acceleration for video playback.

# :question: FAQ - Fedora Setup Script

- [What is this script for?](#what-is-this-script-for)
- [Which Fedora versions are supported?](#which-fedora-versions-are-supported)
- [Can I use it on other desktop environments, like KDE or XFCE?](#can-i-use-it-on-other-desktop-environments-like-kde-or-xfce)
- [Does the script support TPM decryption?](#does-the-script-support-tpm-decryption)
- [How can I report bugs or suggest improvements?](#how-can-i-report-bugs-or-suggest-improvements)
- [What license is the script under?](#what-license-is-the-script-under)

---

## <a id="what-is-this-script-for"></a> :wrench: What is this script for?

This script automates post-installation tasks on **Fedora Workstation**:

- Update your system
- Disable Fedora Flatpaks and redundant RPMFusion repositories
- Install BTRFS Assistant
- Setup BTRFS management
- Setup boot snapshots for root
- Install SELinux Troubleshooter
- Install RPMFusion repositories
- Install multimedia codecs [RPMFusion/Howto/Multimedia](https://rpmfusion.org/Howto/Multimedia?highlight=%28%5CbCategoryHowto%5Cb%29)
- Install NVIDIA drivers if an NVIDIA gpu is detected
- Replace Rhythmbox with GNOME default apps (Decibel and Music)
- Install and enable AppIndicator and KStatusNotifierItem Support
- Replace RPMs with Flatpaks for recommended apps (Fedora Media Writer, Boxes, Libreoffice, Firefox)
- Install Extension Manager, Flatseal and Gear Lever using Flatpak
- Configure TPM decryption (**The user will be prompted for it and can choose not to enable TPM decryption**)

---

## <a id="which-fedora-versions-are-supported"></a> :computer: Which Fedora versions are supported?

The script is intended for the **latest version of Fedora Workstation** **(Fedora Linux 42)** using the **GNOME** desktop environment.

---

## <a id="can-i-use-it-on-other-desktop-environments-like-kde-or-xfce"></a> :warning: Can I use it on other desktop environments, like KDE or XFCE?

The script is **only tested on GNOME** and installs components specific to GNOME.  
For example, on KDE, the autostart terminal window does not appear correctly.  
Other desktop environments are **not supported or tested**, but I intend to test them in the future.

---

## <a id="does-the-script-support-tpm-decryption"></a> :closed_lock_with_key: Does the script support TPM decryption?

Yes! The repository includes a script named `tpm.sh` that allows you to configure **TPM-based disk decryption**.  
This enables your system to automatically unlock encrypted drives during boot using the **TPM (Trusted Platform Module)**.

---

## <a id="how-can-i-report-bugs-or-suggest-improvements"></a> :bug: How can I report bugs or suggest improvements?

You can open an issue in the [Issues section](https://github.com/Fail-gh/Fedora-Setup-Script/issues) of the GitHub repository.  
If you have feature suggestions or bug reports, please describe them clearly and include steps to reproduce if applicable.

---

## <a id="what-license-is-the-script-under"></a> :page_facing_up: What license is the script under?

The script is released under the **GNU General Public License v3.0 (GPL-3.0)**.  
This license allows you to freely use, modify, and distribute the script, as long as any derivative work is also released under the same license.
