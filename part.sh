#!/usr/bin/env bash

. modules/load-config

disk_path=/dev/$disk_dev
parted $disk_path mklabel gpt
parted $disk_path mkpart esp fat32 $efi_start $efi_end
parted $disk_path name 1 esp
parted $disk_path set 1 esp on
parted $disk_path mkpart primary $boot_type $boot_start $boot_end
parted $disk_path name 2 boot
parted $disk_path set 2 boot on
parted $disk_path mkpart primary $boot_end 100%
parted $disk_path name 3 lvm
parted $disk_path set 3 lvm on
