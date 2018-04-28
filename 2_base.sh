#!/usr/bin/env bash

. modules/init

vgchange -a y ${lvm_group}

# format system folders
swapoff ${lvm_swap}
mkswap -f ${lvm_swap}
swapon ${lvm_swap}

#format all system disks
umount ${root_mount}/proc
umount ${root_mount}/sys
umount ${root_mount}/sys
umount ${root_mount}/dev
umount ${root_mount}/dev
umount ${root_mount}
umount ${efi_mount}
umount ${boot_mount}
# unmount any data partitions
for lvm_data in ${lvm_datas[*]}; do
    lvm_data_mount="$(part_mount ${lvm_data})"
    if [[ "" != "${lvm_data_mount}" ]]; then
        umount ${lvm_data_mount}
    fi
done
umount ${root_mount}
mkfs -t ${boot_type} ${boot_dev}
mkfs -t ${lvm_root_type} -f ${lvm_root}


# ask if data partitions should be formatted
for lvm_data in ${lvm_datas[*]}; do
    lvm_type="$(part_type ${lvm_data})"
    lvm_device="/dev/$(part_lvm_group ${lvm_data})/$(part_label ${lvm_data})"
    format_data='n'
    if [[ "" != "${lvm_type}" ]]; then
        read -p "Format data directory(y/n)?" format_data
        if [[ ${format_data} = 'y' ]]; then
            mkfs -t ${lvm_type} -f ${lvm_device}
        fi
    fi
done

mkdir -p ${root_mount}
mount ${lvm_root} ${root_mount}
mkdir -p ${root_mount}/tmp
chmod 1777 ${root_mount}/tmp

ntpd -q -g

links https://www.gentoo.org/downloads/mirrors/

tar xpf stage3-*.tar.* --xattrs-include='*.*' --numeric-owner -C ${root_mount}
config_set ${root_mount}/etc/portage/make.conf USE "${global_use}"
config_set ${root_mount}/etc/portage/make.conf LINGUAS "zh en"
config_set ${root_mount}/etc/portage/make.conf L10N "zh-CN en-US"
config_set ${root_mount}/etc/portage/make.conf ACCEPT_LICENSE "*"
config_set ${root_mount}/etc/portage/make.conf GRUB_PLATFORMS "efi-64"
config_set ${root_mount}/etc/portage/make.conf CFLAGS "-march=native -O2 -pipe"
config_set ${root_mount}/etc/portage/make.conf CXXFLAGS "\${CFLAGS}"
config_set ${root_mount}/etc/portage/make.conf MAKEOPTS "-j${n_core}"
config_set ${root_mount}/etc/portage/make.conf GENTOO_MIRRORS "http://mirrors.163.com/gentoo"
config_set ${root_mount}/etc/portage/make.conf VIDEO_CARDS "nvidia"

mkdir -p ${root_mount}/etc/portage/repos.conf
cp ${root_mount}/usr/share/portage/config/repos.conf ${root_mount}/etc/portage/repos.conf/gentoo.conf
cp --dereference /etc/resolv.conf ${root_mount}/etc/
mount --types proc /proc ${root_mount}/proc
mount --rbind /sys ${root_mount}/sys
mount --make-rslave ${root_mount}/sys
mount --rbind /dev ${root_mount}/dev
mount --make-rslave ${root_mount}/dev

cp -r . ${root_mount}/root/install
chroot ${root_mount} /bin/bash