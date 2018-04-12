#!/usr/bin/env bash

. modules/init

source /etc/profile
export PS1="(chroot) ${PS1}"

mkdir -p $boot_mount
mount $boot_dev $boot_mount

# Sync portage
emerge-webrsync
emerge --sync

# Choose profile
chosen_profile=''
confirm_profile='n'
while [[ $chosen_profile -le 0 || $confirm_profile != 'y' ]]; do
    eselect profile list | more
    read -p "Profile number to choose: " chosen_profile
    read -p "You have chosen $chosen_profile. Correct(y/n)?" confirm_profile
done
eselect profile set $chosen_profile

# Choose timezone
echo "Asia/Chongqing" > /etc/timezone
emerge --config sys-libs/timezone-data

# locale
echo "en_US ISO-8859-1" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=\"zh_CN.UTF-8\"" >> /etc/env.d/02locale
echo "LC_COLLATE=\"zh_CN.UTF-8\"" >> /etc/env.d/02locale
echo "LC_CTYPE=\"en_US.UTF-8\"" >> /etc/env.d/02locale
config_set /etc/rc.conf unicode yes
env-update && source /etc/profile && export PS1="(chroot) $PS1"

# setup fstab
echo "$boot_dev /boot $boot_type defaults,noatime 0 2" >> /etc/fstab
echo "$efi_dev /boot/efi vfat defaults 0 1" >> /etc/fstab
echo "$lvm_swap none swap defaults 0 0" >> /etc/fstab
echo "$lvm_root / $lvm_root_type defaults,noatime 0 1" >> /etc/fstab
echo "$lvm_home /home $lvm_home_type defaults,noatime 0 2" >> /etc/fstab
mount /boot
mkdir -p /boot/efi
mount /boot/efi
mount /home

# kernel
emerge --ask sys-kernel/gentoo-sources
cd /usr/src/linux; make defconfig
config_set /usr/src/linux/.config CONFIG_XFS_FS 'y'
config_set /usr/src/linux/.config CONFIG_USB_XHCI_HCD 'y'
make && make modules_install && make install


