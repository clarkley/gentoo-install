#!/usr/bin/env bash

. modules/init

host_name=''
read -p "Hostname: " host_name
config_set /etc/conf.d/hostname hostname $host_name

#install network tools
emerge --ask --noreplace -net-misc/netifrc
read -p
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