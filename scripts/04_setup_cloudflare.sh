#!/bin/bash
set -e

# Load environment variables
ENV_FILE="$(dirname "$0")/../.env"
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
fi

echo "=========================================================="
echo "  [4/4] ☁️ MENGAKTIFKAN CLOUDFLARE TUNNEL (REMOTE ACCESS)  "
echo "=========================================================="

echo "-> Checking cloudflared installation..."
if ! command -v cloudflared &> /dev/null; then
    echo "-> Menginstall cloudflared..."
    curl -L -o /tmp/cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    dpkg -i /tmp/cloudflared.deb
    rm -f /tmp/cloudflared.deb
fi

echo "-> Membuat Systemd Service Cloudflare Quick Tunnel..."
cat << EOF > /etc/systemd/system/cloudflared-nas.service
[Unit]
Description=Cloudflare Tunnel for NAS Filebrowser
After=network.target filebrowser.service

[Service]
User=root
ExecStart=/usr/bin/cloudflared tunnel --url http://localhost:$CLOUDFLARE_TUNNEL_PORT
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now cloudflared-nas.service

echo "-> Menunggu perolehan URL HTTPS Publik dari Cloudflare..."
sleep 5
URL=$(journalctl -u cloudflared-nas.service -n 100 | grep -o 'https://[-a-zA-Z0-9]*\.trycloudflare\.com' | tail -n 1)

echo "=========================================================="
echo "  🎉 CLOUDFLARE TUNNEL BERHASIL DIAKTIFKAN! 🎉           "
echo "=========================================================="
if [ -n "$URL" ]; then
    echo "URL Akses Publik HTTPS : $URL"
else
    echo "URL Tunnel Publik Anda:"
    journalctl -u cloudflared-nas.service -n 100 | grep -o 'https://[-a-zA-Z0-9]*\.trycloudflare\.com' | tail -n 1
fi
echo "=========================================================="
