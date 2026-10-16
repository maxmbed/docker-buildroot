#!/bin/sh

set -u
set -e

# Add a console on tty1
if [ -e ${TARGET_DIR}/etc/inittab ]; then
    grep -qE '^tty1::' ${TARGET_DIR}/etc/inittab || \
	sed -i '/GENERIC_SERIAL/a\
tty1::respawn:/sbin/getty -L  tty1 0 vt100 # QEMU graphical window' ${TARGET_DIR}/etc/inittab
fi


# Set the default systemd target to weston graphical
mkdir -p "${TARGET_DIR}/etc/systemd/system/graphical.target.wants"

ln -sf /usr/lib/systemd/system/graphical.target \
       "${TARGET_DIR}/etc/systemd/system/default.target"

ln -sf "${TARGET_DIR}/etc/systemd/system/weston.service" \
       "${TARGET_DIR}/etc/systemd/system/graphical.target.wants/weston.service"
