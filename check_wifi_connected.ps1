adb connect 192.168.31.157:5555
Start-Sleep -Seconds 4

adb -s 192.168.31.157:5555 shell "ip addr show wlan0"
adb -s 192.168.31.157:5555 shell "cmd wifi status"
adb -s 192.168.31.157:5555 shell "dumpsys wifi | grep -iE 'mWifiInfo|Link speed|frequency|mTxLinkSpeedMbps|mRxLinkSpeedMbps'"
