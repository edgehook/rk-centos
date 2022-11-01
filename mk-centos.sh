#!/bin/bash -e
ARCH="arm64"

TARGET_ROOTFS_DIR="binary"
CENTOS_BASE_IMG="CentOS-base-7-aarch64-2009.tar.gz"


# binary directory 
if [ -d $TARGET_ROOTFS_DIR ]; then
	sudo rm -rf $TARGET_ROOTFS_DIR
	echo "\033[36m remove exits $TARGET_ROOTFS_DIR directory\033[0m"
fi

if [ -e $CENTOS_BASE_IMG ]; then
	sudo rm -rf $CENTOS_BASE_IMG
fi
sudo cat centos-base/CentOS-base-7-aarch64-*.tar.gz* > $CENTOS_BASE_IMG

if [ ! -e $CENTOS_BASE_IMG ]; then
	echo "\033[36m please make sure $CENTOS_BASE_IMG file exits\033[0m"
	exit -1
fi

if [ ! -d $TARGET_ROOTFS_DIR ]; then
	sudo mkdir -p $TARGET_ROOTFS_DIR
	sudo tar -zxf $CENTOS_BASE_IMG -C $TARGET_ROOTFS_DIR
    sudo cp -f /etc/resolv.conf $TARGET_ROOTFS_DIR/etc/

	if [ "$ARCH" == "armhf" ]; then
		sudo cp /usr/bin/qemu-arm-static $TARGET_ROOTFS_DIR/usr/bin/
	elif [ "$ARCH" == "arm64"  ]; then
		sudo cp /usr/bin/qemu-aarch64-static $TARGET_ROOTFS_DIR/usr/bin/
	fi
fi

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

#copy overlay-adv
cp -rfp overlay-adv/* $TARGET_ROOTFS_DIR/

#copy yum packages
sudo mkdir -p $TARGET_ROOTFS_DIR/packages
sudo cp -rf packages_minimal/*.rpm  $TARGET_ROOTFS_DIR/packages


echo "\033[36m Change root.....................\033[0m"
cat << EOF | chroot $TARGET_ROOTFS_DIR

#install yum rpm
cd packages/
#rpm -ivh python-2.7.5-89.el7.aarch64.rpm python-iniparse-0.4-9.el7.noarch.rpm --nodeps --force
#rpm -ivh yum-3.4.3-168.el7.centos.noarch.rpm yum-metadata-parser-1.1.4-10.el7.aarch64.rpm yum-plugin-fastestmirror-1.1.31-54.el7_8.noarch.rpm --nodeps --force
#rpm -ivh centos-release-7-9.2009.0.el7.centos.aarch64.rpm --nodeps --force

#install other minimal iso rpm, example NetworkManager,dhcp...
rpm -ivh *.rpm --nodeps --force

#install gnome desktop
yum groupinstall -y "X Window System"
#yum groupinstall -y "GNOME Desktop"
yum install -y gnome-classic-session gnome-terminal nautilus-open-terminal control-center liberation-mono-fonts

#remove dev-log
rm -rf /run/systemd/journal/dev-log

#remove packages directory
rm -rf /packages/*.rpm

EOF

sudo umount $TARGET_ROOTFS_DIR/proc
sudo umount $TARGET_ROOTFS_DIR/sys
sudo umount $TARGET_ROOTFS_DIR/dev

#make adv
./mk-adv.sh

#make image
./mk-image.sh


