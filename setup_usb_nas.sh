#!/data/data/com.termux/files/usr/bin/bash
export PREFIX=/data/data/com.termux/files/usr
export HOME=/data/data/com.termux/files/home
export PATH=$PREFIX/bin:$PATH
export LD_PRELOAD=$PREFIX/lib/libtermux-exec.so
export DEBIAN_FRONTEND=noninteractive

termux-wake-lock 2>/dev/null || true

# 1. Stop and purge heavy VNC, XFCE, Debian proot, and redundant MiniDLNA/Aria2
vncserver -kill :1 >/dev/null 2>&1 || true
pkill -f xfce4 >/dev/null 2>&1 || true
pkill -f minidlnad >/dev/null 2>&1 || true
pkill -f aria2c >/dev/null 2>&1 || true
pkg uninstall -y proot-distro tigervnc x11-repo minidlna aria2 >/dev/null 2>&1 || true
rm -rf $PREFIX/var/lib/proot-distro ~/.vnc ~/auto_vnc.sh /sdcard/auto_vnc.sh /sdcard/init_linux_desktop.sh
pkg autoclean -y

# 2. Install lightweight NAS packages (Samba SMB server, FileBrowser Web NAS, OpenSSH SFTP)
pkg update -y && pkg install -y samba filebrowser openssh

# 3. Create unified NAS Root and USB mount symlink folder
mkdir -p /sdcard/NAS_Root/Internal_Media
mkdir -p /sdcard/NAS_Root/External_Drives

# 4. Create dynamic USB External Drive Auto-Mounter & Watchdog script
cat << 'EOF' > ~/usb_nas_watchdog.sh
#!/data/data/com.termux/files/usr/bin/bash
export PREFIX=/data/data/com.termux/files/usr
export PATH=$PREFIX/bin:$PATH
while true; do
    # Clean broken symlinks when a USB drive is unplugged
    find /sdcard/NAS_Root/External_Drives -xtype l -delete 2>/dev/null
    # Scan /storage for connected external USB drives and link them
    for vol in /storage/*; do
        volname=$(basename "$vol")
        if [ "$volname" != "emulated" ] && [ "$volname" != "self" ] && [ -d "$vol" ]; then
            ln -sfn "$vol" "/sdcard/NAS_Root/External_Drives/USB_$volname" 2>/dev/null
            # Create Android/data/com.termux sandbox folder on external drive for full write support
            mkdir -p "$vol/Android/data/com.termux/files" 2>/dev/null
        fi
    done
    sleep 10
done
EOF
chmod +x ~/usb_nas_watchdog.sh

# 5. Configure Samba Server on Non-Root Port 4445 exposing Internal + Connected USB Drives
mkdir -p $PREFIX/etc/samba
WHOAMI=$(whoami)
cat << EOF > $PREFIX/etc/samba/smb.conf
[global]
workgroup = WORKGROUP
server string = Jio STB USB NAS
security = user
map to guest = Bad User
smb ports = 4445
max protocol = SMB3
min protocol = SMB2
socket options = TCP_NODELAY SO_RCVBUF=524288 SO_SNDBUF=524288
read raw = yes
write raw = yes

[Jio_NAS]
path = /sdcard/NAS_Root
writable = yes
browseable = yes
guest ok = yes
force user = $WHOAMI

[USB_Storage]
path = /storage
writable = yes
browseable = yes
guest ok = yes
force user = $WHOAMI
EOF
echo -e "123456\n123456" | smbpasswd -a -s -L -c $PREFIX/etc/samba/smb.conf $WHOAMI 2>/dev/null || true

# 6. Configure FileBrowser Web NAS UI on Port 8080 pointed directly to /storage (shows both Internal & External USB drives)
pkill -f filebrowser >/dev/null 2>&1 || true
rm -f ~/.config/filebrowser.db
filebrowser config init --database ~/.config/filebrowser.db
filebrowser config set --address 0.0.0.0 --port 8080 --root /storage --database ~/.config/filebrowser.db
filebrowser users add admin 123456 --perm.admin --database ~/.config/filebrowser.db

# 7. Configure OpenSSH SFTP Server on Port 8022 (Password: 123456)
echo -e "123456\n123456" | passwd

# 8. Build Master Startup Script for Termux and Termux:Boot
cat << 'EOF' > ~/start_nas_services.sh
#!/data/data/com.termux/files/usr/bin/bash
export PREFIX=/data/data/com.termux/files/usr
export PATH=$PREFIX/bin:$PATH
termux-wake-lock 2>/dev/null || true
pgrep -f usb_nas_watchdog.sh >/dev/null || nohup ~/usb_nas_watchdog.sh >/dev/null 2>&1 &
pgrep sshd >/dev/null || sshd
pgrep smbd >/dev/null || smbd -D -s $PREFIX/etc/samba/smb.conf
pgrep filebrowser >/dev/null || nohup filebrowser --database ~/.config/filebrowser.db >/dev/null 2>&1 &
EOF
chmod +x ~/start_nas_services.sh
mkdir -p ~/.termux/boot
cp -f ~/start_nas_services.sh ~/.termux/boot/start_nas_services.sh
sed -i '/start_media_services.sh/d' ~/.bashrc 2>/dev/null || true
grep -q "start_nas_services.sh" ~/.bashrc || echo "~/start_nas_services.sh" >> ~/.bashrc

# 9. Launch NAS Services Immediately
~/start_nas_services.sh
echo "=== ALL NAS SERVICES INITIALIZED ==="
