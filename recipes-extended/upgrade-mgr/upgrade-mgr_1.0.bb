SUMMARY = "Upgrade script for double backup partition"
DESCRIPTION = "Perform upgrade operation against backup partitions."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/LICENSE;md5=4d92cd373abda3937c2bc47fbc49d690"

SRC_URI = "\
	file://upgrade_inactive_partition.sh \
"
FILESEXTRAPATHS_prepend := "${THISDIR}:${THISDIR}/files:"

do_install() {
	install -d ${D}${sbindir}
	install -m 0755 ${WORKDIR}/upgrade_inactive_partition.sh ${D}${sbindir}
}

FILES_${PN} = " \
	${sbindir}/* \
"

