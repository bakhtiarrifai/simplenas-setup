#!/bin/bash
set -e

# Load environment variables
ENV_FILE="$(dirname "$0")/../.env"
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
fi

echo "=========================================================="
echo "  [3/4] 🌐 MENGINSTALL FILEBROWSER (WEB FILE MANAGER)     "
echo "=========================================================="

echo "-> Installing Filebrowser binary..."
if ! command -v filebrowser &> /dev/null; then
    curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
fi

echo "-> Menyiapkan database & admin user..."
systemctl stop filebrowser 2>/dev/null || true
mkdir -p /etc/filebrowser
rm -f "$FILEBROWSER_DB_PATH"

filebrowser config init -d "$FILEBROWSER_DB_PATH" --root "$NAS_MOUNT_POINT" --port "$FILEBROWSER_PORT" --address 0.0.0.0
filebrowser users add "$FILEBROWSER_ADMIN_USER" "$FILEBROWSER_ADMIN_PASS" --perm.admin -d "$FILEBROWSER_DB_PATH"

echo "-> Membuat Systemd Service Filebrowser..."
cat << EOF > /etc/systemd/system/filebrowser.service
[Unit]
Description=Filebrowser Web File Manager
After=network.target mnt-gaia.mount

[Service]
User=root
ExecStart=/usr/local/bin/filebrowser -d $FILEBROWSER_DB_PATH -p $FILEBROWSER_PORT -a 0.0.0.0
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now filebrowser

echo "-> Mengatur Firewall UFW..."
ufw allow "$FILEBROWSER_PORT"/tcp 2>/dev/null || true

echo "✅ [3/4] Filebrowser Web UI Aktif di Port $FILEBROWSER_PORT!"
