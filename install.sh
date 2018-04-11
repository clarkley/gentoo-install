#!/usr/bin/env bash

. modules/init

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