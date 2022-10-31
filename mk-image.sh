#!/bin/bash -e

TARGET_ROOTFS_DIR=./binary
MOUNTPOINT=./rootfs
CENTOS_ROOTFS_IMG="CentOS7-rootfs.img"

echo Making rootfs!

if [ -e $CENTOS_ROOTFS_IMG ]; then
	sudo rm -rf $CENTOS_ROOTFS_IMG
fi
if [ -e ${MOUNTPOINT} ]; then
	sudo rm -rf ${MOUNTPOINT}
fi

dd if=/dev/zero of=${CENTOS_ROOTFS_IMG} bs=1M count=0 seek=8192

finish() {
	sudo umount ${MOUNTPOINT} || true
	echo -e "\e[31m MAKE IMAGE FAILED.\e[0m"
	exit -1
}
trap finish ERR

mkfs.ext4 ${CENTOS_ROOTFS_IMG}

# Create directories
sudo mkdir ${MOUNTPOINT}
sudo mount ${CENTOS_ROOTFS_IMG} ${MOUNTPOINT}

echo Copy rootfs to ${MOUNTPOINT}
sudo cp -rfp ${TARGET_ROOTFS_DIR}/*  ${MOUNTPOINT}

echo Umount rootfs
sudo umount ${MOUNTPOINT}

echo Rootfs Image: ${CENTOS_ROOTFS_IMG}

e2fsck -p -f ${CENTOS_ROOTFS_IMG}
resize2fs -M ${CENTOS_ROOTFS_IMG}
