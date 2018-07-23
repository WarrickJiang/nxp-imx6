COMPATIBLE_MACHINE_nxp-imx6 = "nxp-imx6"
TARGET_SUPPORTED_KTYPES_nxp-imx6 = "standard preempt-rt"

SRC_URI += " \
	file://0001-b08-ethernet-phy-update.patch \
	file://0002-b08-introduce-dts.patch \
	file://0003-seco_b08-enable-usb.patch \
	file://0004-b08-update-usb3503-hub-driver.patch \
	file://0005-C23-Add-preliminary-support-for-C23-board.patch \
	file://0006-imx-watchdog-disable-start-up-checking.patch \
	file://0001-arm-seco-Use-the-new-binding-style-for-the-BT-device.patch \
	file://0007-enable-pcie-m2.patch \
	file://seco_b08.cfg \
"

FILESEXTRAPATHS_prepend := "${THISDIR}:${THISDIR}/files:"
