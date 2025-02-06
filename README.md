# Fedora-Setup-Script

## :warning: Only works with the latest version of Fedora Workstation with GNOME

### :warning: Enable Third Party Repo during first setup

## Install instruction

```
git clone https://github.com/Fail-gh/Fedora-Setup-Script.git

cd Fedora-Setup-Script

chmod +x setup.sh

./setup.sh
```

## :warning: Install Hardware Accelerated Codec for Intel Haswell (4 gen, 2013 or older)

To enable hardware decoding on Intel processors, install the appropriate driver:

```
sudo dnf swap intel-media-driver libva-intel-driver -y
```