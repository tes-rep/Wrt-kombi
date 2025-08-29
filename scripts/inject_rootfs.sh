#!/bin/bash
set -e

BOARD="$openwrt_board"
ROOTFS_IMG="build/file.img.gz"
TARGET_DIR="imagebuilder/bin/targets/amlogic/${BOARD}"
ROOTFS_TAR="${TARGET_DIR}/openwrt-${BOARD}-external-rootfs.tar.gz"

echo "[📦] Extracting rootfs..."
mkdir -p build/extract_rootfs
tar -xzf "$ROOTFS_IMG" -C build/extract_rootfs

echo "[🗂] Repacking to tar.gz for imagebuilder..."
mkdir -p "$TARGET_DIR"
( cd build/extract_rootfs && tar czf "../../../${ROOTFS_TAR}" . )

echo "[🗂] Injecting files/ into rootfs..."
mkdir -p build/inject_rootfs
tar -xzf "$ROOTFS_TAR" -C build/inject_rootfs

# Copy custom files (pastikan folder files/ ada di repo kamu)
cp -a files/* build/inject_rootfs/ || true

# Repack
( cd build/inject_rootfs && tar czf "../../../${ROOTFS_TAR}" . )

# Bersih-bersih
rm -rf build/extract_rootfs build/inject_rootfs

echo "[✅] Done inject. Final rootfs:"
ls -lh "$ROOTFS_TAR"
