#!/bin/bash
set -e

# Load environment variables
ENV_FILE="$(dirname "$0")/../.env"
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
fi

echo "=========================================================="
echo "  [2/4] 🚀 MENGONFIGURASI NAS SERVER & NETWORK DISCOVERY "
echo "=========================================================="

# 1. Struktur Folder NAS
echo "-> Membuat struktur direktori NAS..."
mkdir -p "$NAS_MOUNT_POINT/Media/Movies"
mkdir -p "$NAS_MOUNT_POINT/Media/Music"
mkdir -p "$NAS_MOUNT_POINT/Media/Pictures"
mkdir -p "$NAS_MOUNT_POINT/Documents"
mkdir -p "$NAS_MOUNT_POINT/Backups"
mkdir -p "$NAS_MOUNT_POINT/Downloads"
chmod -R 777 "$NAS_MOUNT_POINT"

# 2. Avahi mDNS / Bonjour Discovery
echo "-> Mengkonfigurasi Avahi Service Discovery..."
systemctl enable --now avahi-daemon 2>/dev/null || true

cat << EOF > /etc/avahi/services/samba.service
<?xml version="1.0" standalone='no'?><!--*-nxml-*-->
<!DOCTYPE service-group SYSTEM "avahi-service-group.dtd">
<service-group>
  <name replace-wildcards="yes">$NAS_SERVER_STRING</name>
  <service>
    <type>_smb._tcp</type>
    <port>445</port>
  </service>
  <service>
    <type>_device-info._tcp</type>
    <port>0</port>
    <txt-record>model=Xserve</txt-record>
  </service>
</service-group>
EOF

systemctl restart avahi-daemon

# 3. Optimasi Samba NAS Configuration
echo "-> Menulis ulang /etc/samba/smb.conf..."
cp /etc/samba/smb.conf /etc/samba/smb.conf.bak 2>/dev/null || true

cat << EOF > /etc/samba/smb.conf
[global]
   workgroup = $NAS_WORKGROUP
   server string = $NAS_SERVER_STRING
   netbios name = $NAS_NETBIOS_NAME
   log file = /var/log/samba/log.%m
   max log size = 1000
   logging = file
   server role = standalone server
   obey pam restrictions = yes
   unix password sync = yes
   pam password change = yes
   map to guest = bad user
   usershare allow guests = yes

   # === OPTIMASI PERFORMA NAS & NETWORK ===
   min protocol = SMB2_10
   max protocol = SMB3
   aio read size = 1
   aio write size = 1
   use sendfile = yes
   dns proxy = no
   ea support = yes
   store dos attributes = yes

   # === OPTIMASI MACOS (APPLE FRUIT) ===
   vfs objects = fruit catia streams_xattr
   fruit:metadata = stream
   fruit:model = MacMini
   fruit:posix_rename = yes
   fruit:veto_appledouble = no
   fruit:wipe_appledouble_in_preview = yes

# === SHARES NAS ===

[Gaia-NAS-All]
   comment = Seluruh Penyimpanan NAS Gaia
   path = $NAS_MOUNT_POINT
   browseable = yes
   writable = yes
   guest ok = yes
   read only = no
   force user = $NAS_LINUX_USER
   create mask = 0777
   directory mask = 0777

[Media]
   comment = Koleksi Film, Video, Musik & Foto
   path = $NAS_MOUNT_POINT/Media
   browseable = yes
   writable = yes
   guest ok = yes
   read only = no
   force user = $NAS_LINUX_USER
   create mask = 0777
   directory mask = 0777

[Documents]
   comment = Dokumen & Berkas Penting
   path = $NAS_MOUNT_POINT/Documents
   browseable = yes
   writable = yes
   guest ok = yes
   read only = no
   force user = $NAS_LINUX_USER
   create mask = 0777
   directory mask = 0777

[Backups]
   comment = Backup Data PC & HP
   path = $NAS_MOUNT_POINT/Backups
   browseable = yes
   writable = yes
   guest ok = yes
   read only = no
   force user = $NAS_LINUX_USER
   create mask = 0777
   directory mask = 0777
EOF

systemctl restart smbd

# 4. Install & Config DLNA Media Server (MiniDLNA)
echo "-> Memasang & Mengkonfigurasi MiniDLNA Server..."
if ! command -v minidlna &> /dev/null; then
    DEBIAN_FRONTEND=noninteractive apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y minidlna -qq
fi

cat << EOF > /etc/minidlna.conf
media_dir=V,$NAS_MOUNT_POINT/Media/Movies
media_dir=A,$NAS_MOUNT_POINT/Media/Music
media_dir=P,$NAS_MOUNT_POINT/Media/Pictures
friendly_name=$MINIDLNA_FRIENDLY_NAME
db_dir=/var/cache/minidlna
log_dir=/var/log/minidlna
inofficial_inotify=yes
album_art_names=Cover.jpg/cover.jpg/AlbumArtSmall.jpg/albumartsmall.jpg/Folder.jpg/folder.jpg
inotify=yes
enable_tivo=no
strict_dlna=no
notify_interval=895
port=$MINIDLNA_PORT
EOF

systemctl enable minidlna
systemctl restart minidlna

# 5. Spin-down HDD Management
echo "-> Mengonfigurasi Spin-down HDD (15 Menit Idle)..."
hdparm -S 180 /dev/disk/by-uuid/"$NAS_HDD_UUID" 2>/dev/null || true

# 6. Firewall rule
echo "-> Menyesuaikan Firewall UFW..."
ufw allow samba 2>/dev/null || true
ufw allow "$MINIDLNA_PORT"/tcp 2>/dev/null || true
ufw allow 5353/udp 2>/dev/null || true

echo "✅ [2/4] NAS Server & Media Server Berhasil Aktif!"
