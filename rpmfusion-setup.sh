#!/bin/sudo bash

#Add feedback when writing sudo password
if ! grep -q pwfeedback /etc/sudoers
then
	echo -e "\n# Enables visual feedback (displaying asterisks) when entering a password\nDefaults pwfeedback" >> /etc/sudoers
fi

#Install BTRFS Assistant
dnf install btrfs-assistant -y

#Auto BTRFS maintenance
sed -i 's|BTRFS_BALANCE_MOUNTPOINTS="/"|BTRFS_BALANCE_MOUNTPOINTS="/:/home"|g' "/etc/sysconfig/btrfsmaintenance"
sed -i 's|BTRFS_SCRUB_MOUNTPOINTS="/"|BTRFS_SCRUB_MOUNTPOINTS="/:/home"|g' "/etc/sysconfig/btrfsmaintenance"

#Configure snapshot of home
snapper -c home create-config /home

cat <<EOF > /etc/snapper/configs/home
# subvolume to snapshot
SUBVOLUME="/home"

# filesystem type
FSTYPE="btrfs"


# btrfs qgroup for space aware cleanup algorithms
QGROUP=""


# fraction or absolute size of the filesystems space the snapshots may use
SPACE_LIMIT="0.5"

# fraction or absolute size of the filesystems space that should be free
FREE_LIMIT="0.2"


# users and groups allowed to work with config
ALLOW_USERS=""
ALLOW_GROUPS=""

# sync users and groups from ALLOW_USERS and ALLOW_GROUPS to .snapshots
# directory
SYNC_ACL="no"


# start comparing pre- and post-snapshot in background after creating
# post-snapshot
BACKGROUND_COMPARISON="yes"


# run daily number cleanup
NUMBER_CLEANUP="yes"

# limit for number cleanup
NUMBER_MIN_AGE="1800"
NUMBER_LIMIT="5"
NUMBER_LIMIT_IMPORTANT="10"


# create hourly snapshots
TIMELINE_CREATE="no"

# cleanup hourly snapshots after some time
TIMELINE_CLEANUP="yes"

# limits for timeline cleanup
TIMELINE_MIN_AGE="1800"
TIMELINE_LIMIT_HOURLY="10"
TIMELINE_LIMIT_DAILY="10"
TIMELINE_LIMIT_WEEKLY="0"
TIMELINE_LIMIT_MONTHLY="10"
TIMELINE_LIMIT_YEARLY="10"


# cleanup empty pre-post-pairs
EMPTY_PRE_POST_CLEANUP="yes"

# limits for empty pre-post-pair cleanup
EMPTY_PRE_POST_MIN_AGE="1800"
EOF

#Configure snapshot of root
snapper -c root create-config /

cat <<EOF > /etc/snapper/configs/root
# subvolume to snapshot
SUBVOLUME="/"

# filesystem type
FSTYPE="btrfs"


# btrfs qgroup for space aware cleanup algorithms
QGROUP=""


# fraction or absolute size of the filesystems space the snapshots may use
SPACE_LIMIT="0.5"

# fraction or absolute size of the filesystems space that should be free
FREE_LIMIT="0.2"


# users and groups allowed to work with config
ALLOW_USERS=""
ALLOW_GROUPS=""

# sync users and groups from ALLOW_USERS and ALLOW_GROUPS to .snapshots
# directory
SYNC_ACL="no"


# start comparing pre- and post-snapshot in background after creating
# post-snapshot
BACKGROUND_COMPARISON="yes"


# run daily number cleanup
NUMBER_CLEANUP="yes"

# limit for number cleanup
NUMBER_MIN_AGE="1800"
NUMBER_LIMIT="5"
NUMBER_LIMIT_IMPORTANT="10"


# create hourly snapshots
TIMELINE_CREATE="no"

# cleanup hourly snapshots after some time
TIMELINE_CLEANUP="yes"

# limits for timeline cleanup
TIMELINE_MIN_AGE="1800"
TIMELINE_LIMIT_HOURLY="10"
TIMELINE_LIMIT_DAILY="10"
TIMELINE_LIMIT_WEEKLY="0"
TIMELINE_LIMIT_MONTHLY="10"
TIMELINE_LIMIT_YEARLY="10"


# cleanup empty pre-post-pairs
EMPTY_PRE_POST_CLEANUP="yes"

# limits for empty pre-post-pair cleanup
EMPTY_PRE_POST_MIN_AGE="1800"
EOF

#Create service for snapshot of home at boot
cat <<EOF > /usr/lib/systemd/system/snapper-boot-home.service
[Unit]
Description=Take snapper snapshot of home on boot
ConditionPathExists=/etc/snapper/configs/home

[Service]
Type=oneshot
ExecStart=/usr/bin/snapper --config home create --cleanup-algorithm number --description "boot"

CapabilityBoundingSet=CAP_DAC_OVERRIDE CAP_FOWNER CAP_CHOWN CAP_FSETID CAP_SETFCAP CAP_SYS_ADMIN CAP_SYS_MODULE CAP_IPC_LOCK CAP_SYS_NICE
LockPersonality=true
NoNewPrivileges=false
PrivateNetwork=true
ProtectHostname=true
RestrictAddressFamilies=AF_UNIX
RestrictRealtime=true
EOF

cat <<EOF > /usr/lib/systemd/system/snapper-boot-home.timer
[Unit]
Description=Take snapper snapshot of home on boot

[Timer]
OnBootSec=1

[Install]
WantedBy=timers.target
EOF

#Enable snapshot of home and root at boot and remove old snapshot
systemctl enable --now snapper-boot.timer
systemctl enable --now snapper-boot-home.timer
systemctl enable --now snapper-cleanup.timer

#Adding RPMFusion repos
dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y

#Enablig OpenH264 for RPM Fusion
dnf4 config-manager --enable fedora-cisco-openh264 -y

#Enable users to install packages using Gnome Software or similar (Only GUI packages)
dnf update @core -y

#Switch to full ffpmeg
dnf swap ffmpeg-free ffmpeg --allowerasing -y

#Allows the application using the gstreamer framework and other multimedia software, to play others restricted codecs
dnf install @multimedia -y
dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
dnf update @sound-and-video -y

#Install Hardware Accelerated Codec for Intel (Use libva-intel-driver for Haswell, 4 gen, 2013 or older)
dnf install intel-media-driver -y

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
dnf install "*-firmware" --exclude=gnome-firmware,python3-virt-firmware -y

#Install Hardware Accelerated Codec for GPU
nvidia=$(lspci | grep NVIDIA)

if [ -n "$nvidia" ]
then
	dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-power vulkan xorg-x11-drv-nvidia-cuda-libs libva-nvidia-driver.{i686,x86_64} libva-utils vdpauinfo -y
	grubby --update-kernel=ALL --args='nvidia-drm.modeset=1'
fi

# Remove RPMFusion setup autostart
rm $PWD/.config/autostart/rpmfusion-setup.desktop

#Wait for the NVIDIA driver to load
reboot=$(systemd-inhibit | grep akmods)

if [ -n "$nvidia" ]
then
	while [ -n "$reboot" ]
	do
		sleep 1
		reboot=$(systemd-inhibit | grep akmods)
	done
fi

mv $PWD/.config/autostart/user-configuration $PWD/.config/autostart/user-configuration.desktop

reboot