#!/data/data/com.termux/files/usr/bin/bash
export PREFIX=/data/data/com.termux/files/usr
export HOME=/data/data/com.termux/files/home
export PATH=$PREFIX/bin:$PATH

mkdir -p $HOME/NAS_Root/External_Drives
mkdir -p $HOME/NAS_Root/Internal_Media
ln -sfn /sdcard $HOME/NAS_Root/Internal_Storage 2>/dev/null

LAST_VOLS=""

while true; do
    # 1. Clean broken symlinks
    find $HOME/NAS_Root/External_Drives -xtype l -delete 2>/dev/null
    find $HOME/NAS_Root -maxdepth 1 -name "USB_Drive" -xtype l -delete 2>/dev/null

    # 2. Discover mounted public storage volumes from /proc/mounts
    VOLS=$(grep -o '/storage/[0-9A-Za-z_-]*' /proc/mounts | grep -v -E '/storage/emulated|/storage/self' | sort -u)

    FIRST_VOL=""
    for vol in $VOLS; do
        volname=$(basename "$vol")
        if [ -n "$volname" ]; then
            ln -sfn "$vol" "$HOME/NAS_Root/External_Drives/USB_$volname" 2>/dev/null
            if [ -z "$FIRST_VOL" ]; then
                FIRST_VOL="$vol"
                ln -sfn "$vol" "$HOME/NAS_Root/USB_Drive" 2>/dev/null
            fi
        fi
    done

    # 3. If volume list changed, dynamically update smb.conf and reload Samba
    if [ "$VOLS" != "$LAST_VOLS" ]; then
        LAST_VOLS="$VOLS"
        if [ -n "$FIRST_VOL" ]; then
            sed -i "s|path = /storage/.*|path = $FIRST_VOL|" $PREFIX/etc/samba/smb.conf 2>/dev/null
            pkill -HUP smbd 2>/dev/null || true
        fi
    fi

    # 4. Self-healing process watchdog: ensure smbd and filebrowser are always alive
    pgrep smbd >/dev/null || smbd -D -s $PREFIX/etc/samba/smb.conf
    pgrep filebrowser >/dev/null || nohup filebrowser --database $HOME/.config/filebrowser.db >> $HOME/nas_startup.log 2>&1 &

    sleep 10
done
