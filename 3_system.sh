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
echo "en_US ISO-8859-1" > /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=\"en_US.UTF-8\"" > /etc/env.d/02locale
echo "LC_COLLATE=\"en_US.UTF-8\"" >> /etc/env.d/02locale
echo "LC_CTYPE=\"en_US.UTF-8\"" >> /etc/env.d/02locale
config_set /etc/rc.conf unicode yes
env-update && source /etc/profile && export PS1="(chroot) $PS1"

# setup fstab
echo "$boot_dev /boot $boot_type defaults,noatime 0 2" >> /etc/fstab
echo "$efi_dev /boot/efi vfat defaults 0 1" >> /etc/fstab
echo "$lvm_swap none swap defaults 0 0" >> /etc/fstab
echo "$lvm_root / $lvm_root_type defaults,noatime 0 1" >> /etc/fstab
echo "$lvm_home /home $lvm_home_type defaults,noatime 0 2" >> /etc/fstab
mount $boot_mount
mkdir -p $efi_mount
mount $efi_mount
mount $lvm_home_mount

emerge --changed-use --deep --with-bdeps=y @world

# kernel
conf=/usr/src/linux/.config
emerge sys-kernel/gentoo-sources sys-kernel/linux-firmware sys-kernel/genkernel
cd /usr/src/linux; make localmodconfig
config_set $conf CONFIG_MODULES 'y' 'n'
config_set $conf CONFIG_MTRR 'y' 'n'
config_remove $conf CONFIG_AGP

config_set $conf CONFIG_FB 'y' 'n'
config_remove $conf CONFIG_FB_NVIDIA
config_remove $conf CONFIG_FB_RIVA
config_remove $conf CONFIG_DRM_NOUVEAU

config_set $conf CONFIG_DEVTMPFS 'y' 'n'
config_set $conf CONFIG_SCSI_MOD 'y' 'n'
config_set $conf CONFIG_SCSI 'y' 'n'
config_set $conf CONFIG_SCSI_DMA 'y' 'n'
config_set $conf CONFIG_SCSI_NETLINK 'y' 'n'
config_set $conf CONFIG_SCSI_MQ_DEFAULT 'y' 'n'
config_set $conf CONFIG_SCSI_PROC_FS 'y' 'n'

config_set $conf CONFIG_XFS_FS 'y' 'n'
config_set $conf CONFIG_PROC_FS 'y' 'n'
config_set $conf CONFIG_PROC_FS_VMCORE 'y' 'n'

config_remove $conf CONFIG_PPP

config_set $conf CONFIG_X86_AMD_PLATFORM_DEVICE 'y' 'n'
config_set $conf CONFIG_MK8 'y' 'n'
config_set $conf CONFIG_CPU_SUP_AMD 'y' 'n'
config_set $conf CONFIG_X86_64_SMP 'y' 'n'
config_set $conf CONFIG_SCHED_SMT 'y' 'n'
config_set $conf CONFIG_SCHED_MC 'y' 'n'
config_set $conf CONFIG_X86_MCE 'y' 'n'
config_set $conf CONFIG_X86_MCE_AMD 'y' 'n'
config_set $conf CONFIG_MICROCODE 'y' 'n'
config_set $conf CONFIG_MICROCODE_AMD 'y' 'n'
config_set $conf CONFIG_PERF_EVENTS_AMD_POWER 'y' 'n'
config_set $conf CONFIG_X86_POWERNOW_K8 'y' 'n'
config_set $conf CONFIG_X86_AMD_FREQ_SENSITIVITY 'y' 'n'
config_set $conf CONFIG_IOMMU_SUPPORT 'y' 'n'
config_set $conf CONFIG_AMD_IOMMU 'y' 'n'
config_set $conf CONFIG_AMD_IOMMU_V2 'y' 'n'

config_set $conf CONFIG_HID 'y' 'n'
config_set $conf CONFIG_HID_BATTERY_STRENGTH 'y' 'n'
config_set $conf CONFIG_HIDRAW 'y' 'n'
config_set $conf CONFIG_UHID 'y' 'n'
config_set $conf CONFIG_HID_GENERIC 'y' 'n'
config_set $conf CONFIG_USB_XHCI_HCD 'y' 'n'
config_set $conf CONFIG_USB_EHCI_HCD 'y' 'n'

config_set $conf CONFIG_IA32_EMULATION 'y' 'n'

config_set $conf CONFIG_PARTITION_ADVANCED 'y' 'n'
config_set $conf CONFIG_EFI_PARTITION 'y' 'n'
config_set $conf CONFIG_EFI_STUB 'y' 'n'
config_set $conf CONFIG_EFI_MIXED 'y' 'n'
config_set $conf CONFIG_EFI_VARS 'y' 'n'

config_set $conf CONFIG_R8169 'y' 'n'
make -j${n_core} && make -j${n_core} modules_install && make install

genkernel --lvm --install initramfs
