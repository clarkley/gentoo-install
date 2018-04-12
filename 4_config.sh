#!/usr/bin/env bash

. modules/init

host_name=''
read -p "Hostname: " host_name
config_set /etc/conf.d/hostname hostname $host_name

#install network tools
emerge --noreplace net-misc/netifrc
touch /etc/conf.d/net
config_set /etc/conf.d/net hostname $host_name

for iface in $(ls /sys/class/net); do
    if [[ $iface != 'lo' ]]; then
        config_set /etc/conf.d/net "config_$iface" dhcp
        ln -s /etc/init.d/net.lo /etc/init.d/net.$iface
        rc-update add net.$iface default
    fi
done

# hosts
echo "127.0.0.1 $host_name localhost" >> /etc/hosts

# change root password
passwd

emerge app-admin/metalog
emerge net-misc/dhcpcd
emerge sys-fs/xfsprogs
rc-update add sshd default

# config bootloader
emerge sys-boot/grub:2
grub-install --target=x86_64-efi --boot-directory=$boot_mount --efi-directory=$efi_mount --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg

# adding an everyday user
read -p "Adding everyday user: " username
useradd -m -G wheel -s /bin/bash $username
passwd $username

echo "Installation completed. Now reboot the computer."