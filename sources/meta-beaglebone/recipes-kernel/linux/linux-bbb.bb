DESCRIPTION = "Linux kernel for Beaglebone Black"

inherit kernel
inherit python3native
require recipes-kernel/linux/linux-yocto.inc

DEPENDS += "openssl-native"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
	git://github.com/beagleboard/linux.git;branch=5.4; \
"

SRCREV = "4ede238e6879921c9fcd57acd6066fa503f6f676"
LINUX_VERSION = "5.4.106"

LINUX_VERSION_EXTENSION = ""
PR = "r1"
PV = "${LINUX_VERSION}+git${SRCREV}"

deltask kernel_configme

do_compile_append() {
	oe_runmake dtbs
}

do_deploy_append() {
	install -d ${DEPLOYDIR}/overlays
	install -m 0644 ${WORKDIR}/linux-beagleboneblack-standard-build/arch/arm/boot/dts/overlays/*.dtbo ${DEPLOYDIR}/overlays
}