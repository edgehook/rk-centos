#!/bin/bash -e
TARGET_ROOTFS_DIR="binary"
RELEASE_VERSION="1.0.0.1"

echo "in mk-adv.sh"

finish() {
	sudo umount $TARGET_ROOTFS_DIR/proc
	sudo umount $TARGET_ROOTFS_DIR/sys
	sudo umount $TARGET_ROOTFS_DIR/dev
    echo -e "\e[31m MAKE CENTOS FAILED.\e[0m"
	exit -1
}
trap finish ERR

sudo mount -t proc /proc $TARGET_ROOTFS_DIR/proc
sudo mount -t sysfs /sys $TARGET_ROOTFS_DIR/sys
sudo mount -o bind /dev $TARGET_ROOTFS_DIR/dev

echo "1.copy overlay"
cp -rfp overlay-adv/* $TARGET_ROOTFS_DIR/

echo "\033[36m Change root.....................\033[0m"
cat << EOF | chroot $TARGET_ROOTFS_DIR

#for login
useradd -m -s /bin/bash centos
echo "centos:123456" | chpasswd

# set zh_CN.UTF-8 for default locale
echo "LANG=zh_CN.UTF-8" >> /etc/locale.conf

## Export env vars
echo "export LC_ALL=zh_CN.UTF-8" >> ~/.bashrc
echo "export LANG=zh_CN.UTF-8" >> ~/.bashrc
echo "export LANGUAGE=zh_CN.UTF-8" >> ~/.bashrc

source ~/.bashrc

#timezone
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo "Asia/Shanghai" > /etc/timezone

#mount userdata to /userdata
rm /userdata /oem /misc -rf
mkdir /userdata
mkdir /oem
chmod 0777 /userdata
chmod 0777 /oem
ln -s /dev/disk/by-partlabel/misc /misc

#fixup serial login error
ln -s /dev/null /etc/systemd/system/plymouth-start.service

echo "Adding advantech-info to /etc/os-release..."
echo "ADVANTECH_INFO=\"Beta release version:${RELEASE_VERSION}\"" >> /etc/os-release

echo "Adding build-info to /etc/os-release..."
echo "BUILD_INFO=\"$(whoami)@$(hostname) $(date)${@:+ - $@}\"" >> /etc/os-release

EOF

sudo umount $TARGET_ROOTFS_DIR/proc
sudo umount $TARGET_ROOTFS_DIR/sys
sudo umount $TARGET_ROOTFS_DIR/dev


