#!/usr/bin/env bash

. modules/init

host_name=''
read -p "Hostname: " host_name
config_set /etc/conf.d/hostname hostname ${host_name}

#install network tools
emerge --noreplace net-misc/netifrc
touch /etc/conf.d/net
config_set /etc/conf.d/net hostname ${host_name}
config_set /etc/conf.d/net dns_domain_lo ${net_domain}

for iface in $(ls /sys/class/net); do
    if [[ $iface != 'lo' ]]; then
        config_set /etc/conf.d/net "config_${iface}" dhcp
        ln -s /etc/init.d/net.lo /etc/init.d/net.${iface}
        rc-update add net.${iface} default
    fi
done

# change root password
passwd

# install additional tools
for tool in ${packages_install[*]}; do
    emerge ${tool}
done
# adding startup apps
for auto_tool in ${auto_tools[*]}; do
    rc-update add ${auto_tool} default
done

# config bootloader
emerge sys-boot/grub:2
config_set /etc/default/grub GRUB_PRELOAD_MODULES ${grub_modules}
config_set /etc/default/grub GRUB_CMDLINE_LINUX_DEFAULT "${grub_params}"
config_set /etc/default/grub GRUB_TERMINAL console
grub-install --target=x86_64-efi --boot-directory=${boot_mount} --efi-directory=${efi_mount} --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg

# adding an everyday user
read -p "Adding everyday user: " username
useradd -m -G wheel -s /bin/bash ${username}
passwd ${username}

emerge --depclean --ask

echo "Installation completed. Now reboot the computer."
