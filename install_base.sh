#!/usr/bin/env bash

. modules/init

# format system folders
mkswap $lvm_swap
mkfs -t $boot_type $boot_dev
mkfs -t $lvm_root_type $lvm_root
mkfs -t $lvm_home_type $lvm_home

swapon $lvm_swap

root=/mnt/gentoo
mkdir -p $root
mount $lvm_root $root
mkdir -p $root/tmp
chmod 1777 $root/tmp

ntpd -q -g

links https://www.gentoo.org/downloads/mirrors/

tar xpf stage3-*.tar.{bz2,xz} --xattrs-include='*.*' --numeric-owner -C $root
config_set $root/etc/portage/make.conf CFLAGS "-march=native -O2 -pipe"
config_set $root/etc/portage/make.conf CXXFLAGS "\${CFLAGS}"
config_set $root/etc/portage/make.conf MAKEOPTS "-j2"

mirrorselect -i -o >> $root/etc/portage/make.conf
mkdir -p $root/etc/portage/repos.conf
cp $root/usr/share/portage/config/repos.conf $root/etc/portage/repos.conf/gentoo.conf
cp --dereference /etc/resolv.conf $root/etc/
mount --types proc /proc $root/proc
mount --rbind /sys $root/sys
mount --make-rslave $root/sys
mount --rbind /dev $root/dev
mount --make-rslave $root/dev

cp -r . $root/root/install
chroot $root /bin/bash