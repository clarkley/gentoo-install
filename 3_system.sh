#!/usr/bin/env bash

. modules/init

source /etc/profile
export PS1="(chroot) ${PS1}"

mkdir -p ${boot_mount}
mount ${boot_dev} ${boot_mount}

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
echo "${boot_dev} /boot ${boot_type} defaults,noatime 0 2" >> /etc/fstab
echo "${efi_dev} /boot/efi vfat defaults 0 1" >> /etc/fstab
echo "${lvm_swap} none swap defaults 0 0" >> /etc/fstab
echo "${lvm_root} / $lvm_root_type defaults,noatime 0 1" >> /etc/fstab
mount ${boot_mount}
mkdir -p ${efi_mount}
mount ${efi_mount}

for lvm_data in ${lvm_datas[*]}; do
    lvm_mount="$(part_mount ${lvm_data})"
    if [[ "" != "${lvm_mount}" ]]; then
        echo "/dev/$(part_lvm_group ${lvm_data})/$(part_label ${lvm_data}) ${lvm_mount} $(part_type ${lvm_data}) defaults,noatime 0 2" >> /etc/fstab
        mkdir -p ${lvm_mount}
        mount ${lvm_mount}
    fi
done

emerge app-portage/cpuid2cpuflags
echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags
emerge --update --changed-use --deep --with-bdeps=y @world

# kernel
conf=/usr/src/linux/.config
emerge sys-kernel/gentoo-sources sys-kernel/linux-firmware sys-kernel/genkernel
cd /usr/src/linux; make defconfig

# adding kernel builtins needed
for adding in ${kernel_builtin_adds[*]}; do
    config_set ${conf} ${adding} 'y' 'n'
done

# adding kernel modules needed
for adding in ${kernel_module_adds[*]}; do
    config_set ${conf} ${adding} 'm' 'n'
done

# remove unnecessary kernel modules
for removal in ${kernel_mod_removals[*]}; do
    config_remove ${conf} ${removal}
done

make -j${n_core} && make -j${n_core} modules_install && make install

genkernel --lvm --install initramfs
