SUMMARY = "U-Boot boot.scr SD boot environment generation for nxp-imx6 targets"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

INHIBIT_DEFAULT_DEPS = "1"
PACKAGE_ARCH = "${MACHINE_ARCH}"

DEPENDS = "u-boot-mkimage-native u-boot-imx"

inherit deploy

do_compile(){

    cat <<EOF > ${WORKDIR}/uEnv.txt

setenv machine_name nxp-imx6
setenv fdt_file ${SECO_DEFAULT_DTB}
setenv mmcpart 5
setenv rootpart ostree_root=LABEL=otaroot
setenv bootpart
setenv mmcpart_r 7
setenv rootpart_r ostree_root=LABEL=otaroot_b
setenv bootpart_r ostree_boot=LABEL=otaboot_b
if fatload mmc \${mmcdev}:1 \${fdt_addr} boot_b_flag;then setenv mmcpart 7;setenv rootpart ostree_root=LABEL=otaroot_b;setenv bootpart ostree_boot=LABEL=otaboot_b;setenv mmcpart_r 5; setenv rootpart_r ostree_root=LABEL=otaroot; setenv bootpart_r ostree_boot=LABEL=otaboot;echo "using B, rollback A";else echo "using A, rollback B";fi
if test -n \${rollback_f} && test \${rollback_f} = yes;then setenv mmcpart \${mmcpart_r}; setenv rootpart \${rootpart_r}; setenv bootpart \${bootpart_r}; echo "Perform rollback";fi
setenv loadenvscript ext4load mmc \${mmcdev}:\${mmcpart} \${loadaddr} /loader/uEnv.txt
run loadenvscript  && env import -t \${loadaddr} 0x40000
setenv loadkernel ext4load mmc \${mmcdev}:\${mmcpart} \${loadaddr} /\${kernel_image}
setenv loadramdisk ext4load mmc \${mmcdev}:\${mmcpart} \${initrd_addr} /\${ramdisk_image}
setenv loaddtb ext4load mmc \${mmcdev}:\${mmcpart} \${fdt_addr} /\${bootdir}/\${fdt_file}
run loadramdisk
run loaddtb
run loadkernel
setenv bootargs \${bootargs} \${bootpart} \${rootpart} console=\${console},\${baudrate} \${smp}
bootz \${loadaddr} \${initrd_addr} \${fdt_addr}
EOF

    mkimage -A arm -T script -O linux -d ${WORKDIR}/uEnv.txt ${WORKDIR}/boot.scr
}

FILES_${PN} += "/boot/boot.scr"

do_install() {
        install -d  ${D}/boot
	install -Dm 0644 ${WORKDIR}/boot.scr ${D}/boot/
}

do_deploy() {
	install -Dm 0644 ${WORKDIR}/boot.scr ${DEPLOYDIR}/boot.scr
}
addtask do_deploy after do_compile before do_build

