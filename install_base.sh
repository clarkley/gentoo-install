#!/usr/bin/env bash

. modules/init

vgchange -a y $lvm_label

# format system folders
swapoff $lvm_swap
mkswap -f $lvm_swap
swapon $lvm_swap

#format all system disks
umount $root_mount/proc
umount $root_mount/sys
umount $root_mount/sys
umount $root_mount/dev
umount $root_mount/dev
umount $root_mount
mkfs -t $boot_type $boot_dev
mkfs -t $lvm_root_type -f $lvm_root

mkdir -p $root_mount
mount $lvm_root $root_mount
mkdir -p $root_mount/tmp
chmod 1777 $root_mount/tmp

ntpd -q -g

links https://www.gentoo.org/downloads/mirrors/

tar xpf stage3-*.tar.* --xattrs-include='*.*' --numeric-owner -C $root_mount
config_set $root_mount/etc/portage/make.conf CFLAGS "-march=native -O2 -pipe"
config_set $root_mount/etc/portage/make.conf CXXFLAGS "\${CFLAGS}"
config_set $root_mount/etc/portage/make.conf MAKEOPTS "-j2"

mirrorselect -i -o >> $root_mount/etc/portage/make.conf
mkdir -p $root_mount/etc/portage/repos.conf
cp $root_mount/usr/share/portage/config/repos.conf $root_mount/etc/portage/repos.conf/gentoo.conf
cp --dereference /etc/resolv.conf $root_mount/etc/
mount --types proc /proc $root_mount/proc
mount --rbind /sys $root_mount/sys
mount --make-rslave $root_mount/sys
mount --rbind /dev $root_mount/dev
mount --make-rslave $root_mount/dev

cp -r . $root_mount/root/install
chroot $root_mount /bin/bash