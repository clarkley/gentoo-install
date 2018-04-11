#!/usr/bin/env bash

. modules/init

source /etc/profile
export PS1="(chroot) ${PS1}"

mkdir -p $boot_mount
mount $boot_dev $boot_mount

emerge-webrsync
emerge --sync
