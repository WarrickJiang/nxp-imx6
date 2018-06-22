#!/bin/sh

partbase=`mount |grep "sysroot " | awk '{print $1}' | awk -F 'p' '{print $1}'`
part=${partbase}'p1'
mkdir -p /tmp/realboot
mount ${part} /tmp/realboot
rm -rf /tmp/realboot/boot_cnt
umount /tmp/realboot
rm -rf /tmp/realboot

