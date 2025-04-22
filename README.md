# Fedora Setup Script

## Install instruction

```
git clone https://github.com/Fail-gh/Fedora-Setup-Script.git

cd Fedora-Setup-Script

chmod +x update.sh

./update.sh
```

## Install Hardware Accelerated Codec for Intel Haswell (4 gen, 2013 or older)

To enable hardware decoding on Intel processors, install the appropriate driver:

```
sudo dnf swap intel-media-driver libva-intel-driver -y
```