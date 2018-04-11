#!/usr/bin/env bash

. modules/init

source /etc/profile
export PS1="(chroot) ${PS1}"

mkdir -p /boot
mount $boot_dev /boot

emerge-webrsync
emerge --sync
