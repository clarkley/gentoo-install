#!/usr/bin/env bash

. modules/init

disk_path=/dev/${disk_dev}
# start a new partition
parted ${disk_path} mklabel gpt

# efi partition
parted -a minimal $disk_path mkpart esp fat32 0% ${efi_end}
parted $disk_path set 1 esp on
mkfs.vfat ${efi_dev}

# boot partition
parted -a minimal $disk_path mkpart boot ${boot_type} ${boot_start} ${boot_end}
mkfs -t ${boot_type} ${boot_dev}

# lvm partition
parted -a minimal ${disk_path} mkpart lvm ${boot_end} 100%
parted ${disk_path} set 3 lvm on

pvcreate ${lvm_dev}
vgcreate ${lvm_group} ${lvm_dev}

# swap partition in lvm
lvcreate -L ${lvm_swap_size} -n swap ${lvm_group}
mkswap ${lvm_swap}

# root partition in lvm
lvcreate -L ${lvm_root_size} -n root ${lvm_group}
mkfs -t ${lvm_root_type} ${lvm_root}

for lvm_data in ${lvm_datas[*]}; do
    # home partition in lvm
    lvm_label="$(part_label ${lvm_data})"
    lvm_data_group="$(part_lvm_group ${lvm_data})"
    lvm_size="$(part_size ${lvm_data})"

    # use the rest of the space if size is empty
    if [[ "" = "${lvm_size}" ]]; then
        lvcreate -l 100%VG -n ${lvm_label} ${lvm_data_group}
    else
        lvcreate -L ${lvm_size} -n root ${lvm_data_group}
    fi

    # format if partition type is defined
    lvm_type="$(part_type ${lvm_data})"
    if [[ "" != "${lvm_type}" ]]; then
        mkfs -t ${lvm_type} /dev/${lvm_data_group}/${lvm_label}
    fi
done