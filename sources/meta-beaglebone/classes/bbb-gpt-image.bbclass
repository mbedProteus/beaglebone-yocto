# Create an image that can be written onto a SD card using dd.

inherit image_types

# Use an uncompressed ext4 by default as rootfs
IMG_ROOTFS_TYPE = "ext4"
IMG_ROOTFS = "${IMGDEPLOYDIR}/${IMAGE_BASENAME}-${MACHINE}.${IMG_ROOTFS_TYPE}"

# This image depends on the rootfs image
IMAGE_TYPEDEP_bbb-gpt-image = "${IMG_ROOTFS_TYPE}"

GPTIMG = "${IMAGE_BASENAME}-${MACHINE}-gpt.img"
BOOT_IMG = "${IMAGE_BASENAME}-${MACHINE}-boot.img"
MLO_LOADER = "${SPL_BINARY}"
UBOOT_LOADER = "u-boot.img"

LOADER1_SIZE = "512"
LOADER2_SIZE = "3072"
ENV_SIZE = "256"
BOOT_SIZE = "40960"

ROOT_UUID_am335x = "7F903FAB-6EBF-42AE-B1E8-8030299AB70C"
GPTIMG_APPEND_am335x = "earlyprintk console=ttyO0,115200n8 rw  root=PARTUUID=${ROOT_UUID} rootfstype=ext4 init=/sbin/init rootwait"

do_image_bbb_gpt_image[depends] += " \
    virtual/bootloader:do_populate_lic \
    parted-native:do_populate_sysroot \
    mtools-native:do_populate_sysroot \
	gptfdisk-native:do_populate_sysroot \
	dosfstools-native:do_populate_sysroot \
    virtual/kernel:do_deploy \
	virtual/bootloader:do_deploy"

IMAGE_CMD_bbb-gpt-image () {
    cd ${DEPLOY_DIR_IMAGE}

    rm -f "${GPTIMG}"
	rm -f "${BOOT_IMG}"

    create_bbb_image

    cd ${DEPLOY_DIR_IMAGE}
	if [ -f ${WORKDIR}/${BOOT_IMG} ]; then
		cp ${WORKDIR}/${BOOT_IMG} ./
	fi
}

create_bbb_image() {
    set -x
    IMG_ROOTFS_SIZE=$(stat -L --format="%s" ${IMG_ROOTFS})
	GPTIMG_MIN_SIZE=$(expr $IMG_ROOTFS_SIZE + \( ${LOADER1_SIZE} + ${LOADER2_SIZE} + ${ENV_SIZE} + ${BOOT_SIZE} + 35 \) \* 512 )
    GPT_IMAGE_SIZE=$(expr $GPTIMG_MIN_SIZE \/ 1024 \/ 1024 + 2)

    dd if=/dev/zero of=${GPTIMG} bs=1M count=0 seek=$GPT_IMAGE_SIZE

    parted -s ${GPTIMG} mklabel gpt

    LOADER1_START=256
    LOADER2_START=$(expr ${LOADER1_START} + ${LOADER1_SIZE})
    ENV_START=$(expr ${LOADER2_START} + ${LOADER2_SIZE})
    BOOT_START=$(expr ${ENV_START} + ${ENV_SIZE})
    ROOTFS_START=$(expr ${BOOT_START} + ${BOOT_SIZE})

    parted -s ${GPTIMG} unit s mkpart mlo ${LOADER1_START} $(expr ${LOADER2_START} - 1)
    parted -s ${GPTIMG} unit s mkpart u-boot ${LOADER2_START} $(expr ${ENV_START} - 1)
    dd if=${DEPLOY_DIR_IMAGE}/${MLO_LOADER} of=${GPTIMG} bs=512 seek=${LOADER1_START} count=${LOADER1_SIZE} conv=notrunc,fsync
    dd if=${DEPLOY_DIR_IMAGE}/${UBOOT_LOADER} of=${GPTIMG} bs=512 seek=${LOADER2_START} count=${LOADER2_SIZE} conv=notrunc,fsync

    parted -s ${GPTIMG} unit s mkpart env ${ENV_START} $(expr ${BOOT_START} - 1)

    BOOT_PART=4
	ROOT_PART=5

    parted -s ${GPTIMG} unit s mkpart boot ${BOOT_START} $(expr ${ROOTFS_START} - 1)
	parted -s ${GPTIMG} set ${BOOT_PART} boot on

    parted -s ${GPTIMG} -- unit s mkpart rootfs ${ROOTFS_START} -34s

    parted ${GPTIMG} print

    gdisk ${GPTIMG} <<EOF
x
c
${ROOT_PART}
${ROOT_UUID}
w
y
EOF
    rm -f ${WORKDIR}/${BOOT_IMG}
    BOOT_BLOCKS=$(LC_ALL=C parted -s ${GPTIMG} unit b print | awk "/ ${BOOT_PART} / { print substr(\$4, 1, length(\$4 -1)) / 512 /2 }")
	BOOT_BLOCKS=$(expr $BOOT_BLOCKS / 63 \* 63)

    mkfs.vfat -n "boot" -S 512 -C ${WORKDIR}/${BOOT_IMG} ${BOOT_BLOCKS}
	mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${MACHINE}.bin ::${KERNEL_IMAGETYPE}
	DTB_NAME=""
	DTB_NAME=$(echo "${KERNEL_DEVICETREE}" | cut -d '/' -f 2)

    mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${DEPLOY_DIR_IMAGE}/${DTB_NAME} ::${DTB_NAME}
    mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${DEPLOY_DIR_IMAGE}/${UBOOT_LOADER} ::u-boot.img
    mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${DEPLOY_DIR_IMAGE}/${MLO_LOADER} ::MLO

	cat >${WORKDIR}/extlinux.conf <<EOF
default bbb

label bbb
	kernel /${KERNEL_IMAGETYPE}
	devicetree /${DTB_NAME}
    append ${GPTIMG_APPEND}
EOF

    mmd -i ${WORKDIR}/${BOOT_IMG} ::/extlinux
    mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${WORKDIR}/extlinux.conf ::/extlinux/

    if [ -d ${DEPLOY_DIR_IMAGE}/overlays ]; then
		mmd -i ${WORKDIR}/${BOOT_IMG} ::/overlays
		mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${DEPLOY_DIR_IMAGE}/overlays/* ::/overlays/
	fi
    if [ -e ${DEPLOY_DIR_IMAGE}/uEnv.txt ]; then
		mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${DEPLOY_DIR_IMAGE}/uEnv.txt ::/
		mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${DEPLOY_DIR_IMAGE}/boot.scr ::/
		if [ -e ${DEPLOY_DIR_IMAGE}/boot.cmd ]; then
			mcopy -i ${WORKDIR}/${BOOT_IMG} -s ${DEPLOY_DIR_IMAGE}/boot.cmd ::/
		fi
	fi

    dd if=${WORKDIR}/${BOOT_IMG} of=${GPTIMG} conv=notrunc,fsync seek=${BOOT_START}
    dd if=${IMG_ROOTFS} of=${GPTIMG} conv=notrunc,fsync seek=${ROOTFS_START}
}