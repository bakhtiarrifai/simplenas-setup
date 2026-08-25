#!/bin/bash
set -e

# Load environment variables
ENV_FILE="$(dirname "$0")/../.env"
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
fi

echo "=========================================================="
echo "  🔑 RESET PASSWORD FILEBROWSER                           "
echo "=========================================================="

systemctl stop filebrowser 2>/dev/null || true
rm -f "$FILEBROWSER_DB_PATH"

filebrowser config init -d "$FILEBROWSER_DB_PATH" --root "$NAS_MOUNT_POINT" --port "$FILEBROWSER_PORT" --address 0.0.0.0
filebrowser users add "$FILEBROWSER_ADMIN_USER" "$FILEBROWSER_ADMIN_PASS" --perm.admin -d "$FILEBROWSER_DB_PATH"

systemctl restart filebrowser

echo "✅ Password Filebrowser berhasil di-reset!"
echo "Username : $FILEBROWSER_ADMIN_USER"
echo "Password : $FILEBROWSER_ADMIN_PASS"
