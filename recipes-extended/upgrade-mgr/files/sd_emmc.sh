#!/bin/sh

sd=mmcblk0
emmc=mmcblk2

label_append="_hd"

#dd basic part
sd3=${sd}p3
test=`fdisk -l /dev/${sd} |awk '/'$sd3'/{print $2}'`
test1=`expr ${test} / 2048`
test1=`expr ${test1} + 1`

dd if=/dev/${sd} of=/dev/${emmc} bs=1M count=$test1 status=progress

#Create last part
cat << EOF > /tmp/fdisk_op
d
3
n
p
3
${test}

Y
w
EOF

fdisk /dev/${emmc} < /tmp/fdisk_op
rm /tmp/fdisk_op
mkfs.ext4 /dev/${emmc}p3 -F
mkdir -p /tmp/mnt0 /tmp/mnt1
mount /dev/${sd}p3 /tmp/mnt0
mount /dev/${emmc}p3 /tmp/mnt1
cp -a /tmp/mnt0 /tmp/mnt1
umount /tmp/mnt0
umount /tmp/mnt1
sync
rm -rf /tmp/mnt0 /tmp/mnt1
e2label /dev/${emmc}p3 fluxdata${label_append}
sleep 0.5
e2label /dev/${emmc}p5 otaboot${label_append}
sleep 0.5
e2label /dev/${emmc}p6 otaroot${label_append}
sleep 0.5
e2label /dev/${emmc}p6 otaroot${label_append}
sleep 0.5
e2label /dev/${emmc}p7 otaboot_b${label_append}
sleep 0.5
e2label /dev/${emmc}p8 otaroot_b${label_append}
sleep 0.5
e2label /dev/${emmc}p8 otaroot_b${label_append}
sync
