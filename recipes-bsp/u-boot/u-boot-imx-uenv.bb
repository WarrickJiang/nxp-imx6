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
setenv rollback_flag no
if test -n \${rollback_f} && test \${rollback_f} = yes && test -n \${kernel_image2} && test -n \${ramdisk_image2} && test -n \${bootdir2} && test -n \${bootargs2};then setenv rollback_flag yes; echo "Perform rollback";fi
setenv loadkernel if test \${rollback_flag} = no\; then ext4load mmc \${mmcdev}:2 \${loadaddr} /\${kernel_image}\; else ext4load mmc \${mmcdev}:2 \${loadaddr} /\${kernel_image2}\;fi\;
setenv loadramdisk if test \${rollback_flag} = no\; then ext4load mmc \${mmcdev}:2 \${initrd_addr} /\${ramdisk_image}\; else ext4load mmc \${mmcdev}:2 \${initrd_addr} /\${ramdisk_image2}\;fi\;
setenv loaddtb if test \${rollback_flag} = no\; then ext4load mmc \${mmcdev}:2 \${fdt_addr} /\${bootdir}\${fdt_file}\; else ext4load mmc \${mmcdev}:2 \${fdt_addr} /\${bootdir2}\${fdt_file}\;fi\;
run loadramdisk
run loaddtb
run loadkernel
if test \${rollback_flag} = no; then setenv bootargs \${bootargs}; else setenv bootargs \${bootargs2};fi;
setenv bootargs \${bootargs} console=\${console},\${baudrate} \${smp}
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

