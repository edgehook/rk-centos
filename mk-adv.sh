#!/bin/bash -e
TARGET_ROOTFS_DIR="binary"

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

EOF

sudo umount $TARGET_ROOTFS_DIR/proc
sudo umount $TARGET_ROOTFS_DIR/sys
sudo umount $TARGET_ROOTFS_DIR/dev


