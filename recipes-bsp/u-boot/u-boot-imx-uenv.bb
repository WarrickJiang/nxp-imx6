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
setenv loadenvscript ext4load mmc \${mmcdev}:2 \${loadaddr} /loader/uEnv.txt
run loadenvscript  && env import -t \${loadaddr} 0x40000
setenv loadkernel ext4load mmc \${mmcdev}:2 \${loadaddr} /\${kernel_image}
setenv loadramdisk ext4load mmc \${mmcdev}:2 \${initrd_addr} /\${ramdisk_image}
setenv loaddtb ext4load mmc \${mmcdev}:2 \${fdt_addr} /\${bootdir}/\${fdt_file}
run loadramdisk
run loaddtb
run loadkernel
setenv bootargs \${bootargs} console=\${console},\${baudrate} \${smp} rdinit=/linuxrc root=/dev/ram0
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

