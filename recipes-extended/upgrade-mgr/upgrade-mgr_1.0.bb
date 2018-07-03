SUMMARY = "Upgrade script for double backup partition"
DESCRIPTION = "Perform upgrade operation against backup partitions."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "\
	file://pulsar_upgrade.sh \
	file://sd_emmc.sh \
"
FILESEXTRAPATHS_prepend := "${THISDIR}:${THISDIR}/files:"

do_install() {
	install -d ${D}${sbindir}
	install -m 0755 ${WORKDIR}/pulsar_upgrade.sh ${D}${sbindir}
	install -m 0755 ${WORKDIR}/sd_emmc.sh ${D}${sbindir}
}

FILES_${PN} = " \
	${sbindir}/* \
"

