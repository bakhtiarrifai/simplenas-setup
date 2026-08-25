#!/bin/bash
set -e

# Load environment variables
ENV_FILE="$(dirname "$0")/../.env"
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
fi

echo "=========================================================="
echo "  [1/4] 🛠️ MEMPROSES SAMBA SHARE & MOUNT PERMANEN HDD     "
echo "=========================================================="

# 1. Membuat mount point
echo "-> Membuat mount point di $NAS_MOUNT_POINT..."
mkdir -p "$NAS_MOUNT_POINT"

# 2. Umount jika ter-mount di lokasi sementara
echo "-> Melepas mount sementara bawaan GUI (jika ada)..."
udisksctl unmount -b /dev/disk/by-uuid/"$NAS_HDD_UUID" 2>/dev/null || umount -l "$NAS_MOUNT_POINT" 2>/dev/null || true
systemctl daemon-reload

# 3. Update /etc/fstab untuk auto-mount dan hotplug
echo "-> Memperbarui /etc/fstab..."
sed -i "/$NAS_HDD_UUID/d" /etc/fstab
echo "UUID=$NAS_HDD_UUID $NAS_MOUNT_POINT $NAS_FILESYSTEM_TYPE defaults,uid=1000,gid=1000,umask=000,nofail,x-systemd.automount,x-systemd.device-timeout=5sec 0 0" >> /etc/fstab
systemctl daemon-reload

# 4. Mount HDD
echo "-> Mounting drive ke $NAS_MOUNT_POINT..."
mount "$NAS_MOUNT_POINT" || mount -a

# 5. Install Samba jika belum terinstall
if ! command -v smbd &> /dev/null; then
    echo "-> Menginstall Samba..."
    apt-get update -qq && apt-get install -y samba -qq
fi

# 6. Enable services
echo "-> Mengaktifkan service Samba & NetBIOS..."
systemctl enable --now smbd
systemctl enable --now nmbd 2>/dev/null || true

echo "✅ [1/4] Samba & Mount HDD Berhasil Dikonfigurasi!"
