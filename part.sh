#!/usr/bin/env bash

. modules/load-config

clearpart --drives=$disk_dev

disk_path=/dev/$disk_dev
parted $disk_path mklabel gpt \
    mkpart esp fat32 $efi_start $efi_end \
    name 1 esp \
    set 1 esp on \
    mkpart primary $boot_type $boot_start $boot_end \
    name 2 boot \
    set 2 boot on
    mkpart primary $boot_end 100%
    name 3 lvm
    set 3 lvm on
