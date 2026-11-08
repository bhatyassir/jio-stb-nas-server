#!/data/data/com.termux/files/usr/bin/bash
export PREFIX=/data/data/com.termux/files/usr
export HOME=/data/data/com.termux/files/home
export PATH=$PREFIX/bin:$PATH
export LD_PRELOAD=$PREFIX/lib/libtermux-exec.so

cd $HOME

# 1. Stop old services
vncserver -kill :1 >/dev/null 2>&1 || true
pkill -f xfce4 >/dev/null 2>&1 || true
pkill -f minidlnad >/dev/null 2>&1 || true
pkill -f aria2c >/dev/null 2>&1 || true
rm -rf $PREFIX/var/lib/proot-distro ~/.vnc ~/auto_vnc.sh /sdcard/auto_vnc.sh /sdcard/init_linux_desktop.sh

# 2. Setup Watchdog Script
cat << 'EOF' > $HOME/usb_nas_watchdog.sh
#!/data/data/com.termux/files/usr/bin/bash
export PREFIX=/data/data/com.termux/files/usr
export PATH=$PREFIX/bin:$PATH
while true; do
    find /sdcard/NAS_Root/External_Drives -xtype l -delete 2>/dev/null
    for vol in /storage/*; do
        volname=$(basename "$vol")
        if [ "$volname" != "emulated" ] && [ "$volname" != "self" ] && [ -d "$vol" ]; then
            ln -sfn "$vol" "/sdcard/NAS_Root/External_Drives/USB_$volname" 2>/dev/null
            mkdir -p "$vol/Android/data/com.termux/files" 2>/dev/null
        fi
    done
    sleep 10
done
EOF
chmod +x $HOME/usb_nas_watchdog.sh

# 3. Configure Samba
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

# 4. Configure FileBrowser
pkill -f filebrowser >/dev/null 2>&1 || true
mkdir -p $HOME/.config
rm -f $HOME/.config/filebrowser.db
filebrowser config init --database $HOME/.config/filebrowser.db
filebrowser config set --address 0.0.0.0 --port 8080 --root /storage --database $HOME/.config/filebrowser.db
filebrowser users add admin 123456 --perm.admin --database $HOME/.config/filebrowser.db

# 5. Set OpenSSH Password
echo -e "123456\n123456" | passwd $WHOAMI 2>/dev/null || true

# 6. Master Startup Script
cat << 'EOF' > $HOME/start_nas_services.sh
#!/data/data/com.termux/files/usr/bin/bash
export PREFIX=/data/data/com.termux/files/usr
export HOME=/data/data/com.termux/files/home
export PATH=$PREFIX/bin:$PATH
export LD_PRELOAD=$PREFIX/lib/libtermux-exec.so

pgrep -f usb_nas_watchdog.sh >/dev/null || nohup $HOME/usb_nas_watchdog.sh >/dev/null 2>&1 &
pgrep sshd >/dev/null || sshd
pgrep smbd >/dev/null || smbd -D -s $PREFIX/etc/samba/smb.conf
pgrep filebrowser >/dev/null || nohup filebrowser --database $HOME/.config/filebrowser.db >/dev/null 2>&1 &
echo "NAS services started."
EOF
chmod +x $HOME/start_nas_services.sh

mkdir -p $HOME/.termux/boot
cp -f $HOME/start_nas_services.sh $HOME/.termux/boot/start_nas_services.sh
sed -i '/start_media_services.sh/d' $HOME/.bashrc 2>/dev/null || true
grep -q "start_nas_services.sh" $HOME/.bashrc || echo "$HOME/start_nas_services.sh" >> $HOME/.bashrc

# 7. Start services
$HOME/start_nas_services.sh
echo "=== NAS PROVISIONING COMPLETE ==="
