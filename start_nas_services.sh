#!/data/data/com.termux/files/usr/bin/bash
export PREFIX=/data/data/com.termux/files/usr
export HOME=/data/data/com.termux/files/home
export PATH=$PREFIX/bin:$PATH
export LD_PRELOAD=$PREFIX/lib/libtermux-exec.so

termux-wake-lock

echo "Starting NAS services at $(date)..." > $HOME/nas_startup.log

# 1. USB Watchdog
pgrep -f usb_nas_watchdog.sh >/dev/null || nohup $HOME/usb_nas_watchdog.sh >> $HOME/nas_startup.log 2>&1 &

# 2. SSHD
pgrep sshd >/dev/null || sshd

# 3. Samba SMB
pgrep smbd >/dev/null || smbd -D -s $PREFIX/etc/samba/smb.conf

# 4. FileBrowser Web UI
pgrep filebrowser >/dev/null || nohup filebrowser --database $HOME/.config/filebrowser.db >> $HOME/nas_startup.log 2>&1 &

echo "NAS services initialized successfully." >> $HOME/nas_startup.log