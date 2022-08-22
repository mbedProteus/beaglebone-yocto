DEFAULT_PREFERENCE = "1"
DESCRIPTION = "Beaglebone Black U-Boot"
LIC_FILES_CHKSUM = "file://Licenses/README;md5=5a7450c57ffe5ae63fd732446b988025"

require u-boot.inc u-boot-common-bbb.inc
SRC_URI = "git://github.com/beagleboard/u-boot;protocol=https;branch=v2021.10-bbb.io-am335x \
    file://0001-custom-u-boot-config.patch \
"
SRCREV = "6988a0462268858874dcc1801aa65450e572fab1"