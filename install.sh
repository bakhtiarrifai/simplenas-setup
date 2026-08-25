#!/bin/bash
set -e

# Pastikan dijalankan sebagai root / sudo
if [ "$EUID" -ne 0 ]; then
  echo "❌ Harap jalankan script ini sebagai root atau dengan sudo:"
  echo "   sudo ./install.sh"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "⚠️ File .env tidak ditemukan! Mengisi dari .env.example..."
    cp "$SCRIPT_DIR/.env.example" "$ENV_FILE"
    echo "💡 Silakan sesuaikan variabel di $ENV_FILE terlebih dahulu jika diperlukan."
fi

# Export .env
export $(grep -v '^#' "$ENV_FILE" | xargs)

echo "=========================================================="
echo "    🚀 DEPLOYMENT MASTER - GAIA FULL NAS STORAGE SERVER   "
echo "=========================================================="
echo "Mount Point : $NAS_MOUNT_POINT"
echo "HDD UUID    : $NAS_HDD_UUID"
echo "User Linux  : $NAS_LINUX_USER"
echo "Web UI Port : $FILEBROWSER_PORT"
echo "=========================================================="

bash "$SCRIPT_DIR/scripts/01_setup_samba.sh"
bash "$SCRIPT_DIR/scripts/02_setup_nas.sh"
bash "$SCRIPT_DIR/scripts/03_setup_filebrowser.sh"
bash "$SCRIPT_DIR/scripts/04_setup_cloudflare.sh"

echo ""
echo "=========================================================="
echo "  🎉 GAIA NAS FULL DEPLOYMENT SUDAH SELESAI! 🎉           "
echo "=========================================================="
echo " Akses Lokal SMB   : \\\\192.168.50.195 atau smb://192.168.50.195"
echo " Akses Web UI Lokal : http://192.168.50.195:$FILEBROWSER_PORT"
echo " User Web UI        : $FILEBROWSER_ADMIN_USER"
echo " Pass Web UI        : $FILEBROWSER_ADMIN_PASS"
echo "=========================================================="
