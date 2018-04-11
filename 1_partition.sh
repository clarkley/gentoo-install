#!/usr/bin/env bash

. modules/init

disk_path=/dev/$disk_dev
# start a new partition
parted $disk_path mklabel gpt

# efi partition
parted -a minimal $disk_path mkpart esp fat32 0% $efi_end
parted $disk_path set 1 esp on
mkfs.vfat $efi_dev

# boot partition
parted -a minimal $disk_path mkpart boot $boot_type $boot_start $boot_end
mkfs -t $boot_type $boot_dev

# lvm partition
parted -a minimal $disk_path mkpart lvm $boot_end 100%
parted $disk_path set 3 lvm on

pvcreate $lvm_dev
vgcreate $lvm_label $lvm_dev

# swap partition in lvm
lvcreate -L $lvm_swap_size -n swap $lvm_label
mkswap $lvm_swap

# root partition in lvm
lvcreate -L $lvm_root_size -n root $lvm_label
mkfs -t $lvm_root_type $lvm_root

# home partition in lvm
lvcreate -l 100%VG -n home $lvm_label
mkfs -t $lvm_home_type $lvm_home