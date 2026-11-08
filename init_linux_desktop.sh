#!/data/data/com.termux/files/usr/bin/bash
pkg update -y && pkg upgrade -y
pkg install x11-repo proot-distro tigervnc pulseaudio -y
proot-distro install debian
proot-distro login debian -- bash -c "apt update && apt install -y xfce4 xfce4-terminal firefox-esr dbus-x11"
mkdir -p ~/.vnc
cat << 'VNC_EOF' > ~/.vnc/xstartup
#!/data/data/com.termux/files/usr/bin/bash
export DISPLAY=:1
proot-distro login debian --shared-tmp -- /bin/bash -c "export DISPLAY=:1; service dbus start; startxfce4"
VNC_EOF
chmod +x ~/.vnc/xstartup
echo "=========================================================="
echo "Linux XFCE4 Ready! Start server with:"
echo "vncserver -geometry 1920x1080 -localhost no :1"
echo "Then open AVNC and connect to 127.0.0.1:5901"
echo "=========================================================="
