#!/usr/bin/env bash

. modules/init

source /etc/profile
export PS1="(chroot) ${PS1}"

mkdir -p $boot_mount
mount $boot_dev $boot_mount

emerge-webrsync
emerge --sync

chosen_profile=''
confirm_profile='n'
while [[ $chosen_profile -le 0 && $confirm_profile = 'y' ]]; do
    emerge profile list | more
    read -p "Profile number to choose: " chosen_profile
    read -p "You have chosen $chosen_profile. Correct(y/n)?"
done
emerge profile set $chosen_profile