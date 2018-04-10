#!/usr/bin/env bash

. modules/load-config

disk_path=/dev/$disk_dev
# start a new partition
parted $disk_path mklabel gpt

# efi partition
parted -a optimal $disk_path mkpart esp fat32 0% $efi_end
parted $disk_path set 1 esp on
mkfs -t fat32 ${disk_path}1

# boot partition
parted -a optimal $disk_path mkpart boot $boot_type $boot_start $boot_end
mkfs -t $boot_type ${disk_path}2

# lvm partition
parted -a optimal $disk_path mkpart lvm $boot_end 100%
parted $disk_path set 3 lvm on

disk_lvm="/dev/${disk_dev}3"
pvcreate $disk_lvm
vgcreate $lvm_label $disk_lvm

# swap partition in lvm
lvcreate -L $lvm_swap_size -n swap $lvm_swap_label
mkswap $lvm_swap
swapon $lvm_swap

# root partition in lvm
lvcreate -L $lvm_root_size -n root $lvm_root_label
mkfs -t $lvm_root_type $lvm_root

# home partition in lvm
lvcreate -l 100%VG -n home $lvm_home_label
mkfs -t $lvm_home_type $lvm_home