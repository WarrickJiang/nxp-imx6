#!/bin/sh

cleanup() {
umount ${upboot} /tmp/sysroot_b/boot
umount ${uproot} /tmp/sysroot_b
rm -rf /tmp/sysroot_b
exit
}

partbase=`mount |grep "sysroot " | awk '{print $1}' | awk -F 'p' '{print $1}'`
partroot=`mount |grep "sysroot " | awk '{print $1}' | awk -F 'p' '{print $2}'`

partbase=${partbase}'p'

rootpart=${partbase}'1'

abflag='B'
upboot=${partbase}'7'
uproot=${partbase}'8'
runboot=${partbase}'5'
runroot=${partbase}'6'
label_append='_b'
if [ x${partroot} = 'x8' ]; then
	abflag='A'
	upboot=${partbase}'5'
	uproot=${partbase}'6'
	runboot=${partbase}'7'
	runroot=${partbase}'8'
	label_append=''
fi
label_pre=""
teststr=`grep "emmc_" /proc/cmdline`
if [ -n "${teststr}" ]; then
	label_pre="emmc_"
fi

#Mount backup device
mkdir -p /tmp/sysroot_b
mount ${uproot} /tmp/sysroot_b
#if failed
testval=$?
if [ $testval -ne 0 ]; then
	dd if=${runroot} of=${uproot} bs=1M
	e2label ${uproot} ${label_pre}otaroot${label_append}
	mount ${uproot} /tmp/sysroot_b
	if [ $testval -ne 0 ]; then
		echo "Fatal error on "${uproot}
		cleanup
	fi
	if [ ! -d /tmp/sysroot_b/ostree/repo ]; then
		echo "Fatal error on "${uproot}/ostree
		cleanup
	fi
fi
mount ${upboot} /tmp/sysroot_b/boot
#if failed
testval=$?
if [ $testval -ne 0 ]; then
	dd if=${runboot} of=${upboot} bs=1M
	e2label ${upboot} ${label_pre}otaboot${label_append}
	mount ${upboot} /tmp/sysroot_b/boot
	testval=$?
	if [ $testval -ne 0 ]; then
		echo "Fatal error on "${upboot}
		cleanup
	fi
fi

#TOOD:pull-local
#ostree pull-local --repo=/tmp/sysroot_b/ostree/repo /sysroot/ostree/repo/ pulsar-linux:cube-gw-ostree-runtime

ostree pull --repo=/tmp/sysroot_b/ostree/repo pulsar-linux:cube-gw-ostree-runtime
testval=$?
if [ $testval -ne 0 ]; then
	echo "Ostree pull failed"
	cleanup
fi

ostree admin --sysroot=/tmp/sysroot_b/ deploy --os=pulsar-linux cube-gw-ostree-runtime
testval=$?
if [ $testval -ne 0 ]; then
	echo "Ostree deploy failed"
	cleanup
fi


umount ${upboot} /tmp/sysroot_b/boot
umount ${uproot} /tmp/sysroot_b

mount ${rootpart} /tmp/sysroot_b
echo "123"${abflag} > /tmp/sysroot_b/boot_ab_flag
umount /tmp/sysroot_b

rm -rf /tmp/sysroot_b

reboot