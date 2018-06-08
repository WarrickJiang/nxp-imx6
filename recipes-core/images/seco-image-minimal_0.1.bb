SUMMARY = "A image for Seco"
DESCRIPTION = "This image only includes the minimal packages for a bootable rootfs \
               and some packages required by Customer \
              "
HOMEPAGE = "http://www.windriver.com"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302 \
                    file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"


CUBE_DOM_GW_EXTRA_INSTALL ?= ""

IMAGE_FSTYPES = "tar.bz2"

IMAGE_INSTALL += "packagegroup-core-boot \
                  packagegroup-core-full-cmdline \
		  flatpak \
                  "
#Customer required
IMAGE_INSTALL += "libmodbus"
IMAGE_INSTALL += "nodejs"

inherit flux-ota core-image
inherit builder-base