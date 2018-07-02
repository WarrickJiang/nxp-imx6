SUMMARY = "Script for deploy ostree repo URL into WIC"
DESCRIPTION = "Script perform deploy upgrade channel work."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "\
	file://ostree-deploy.sh \
"
FILESEXTRAPATHS_prepend := "${THISDIR}:${THISDIR}/files:"

inherit nativesdk

S="${WORKDIR}"

do_install () {
	install -d ${D}/${datadir}/
	install -m 0755 ${S}/ostree-deploy.sh ${D}/${datadir}/
}

FILES_${PN} += " \
	${datadir}/* \
"
