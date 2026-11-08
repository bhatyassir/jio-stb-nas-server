@echo off
setlocal
set TARGET_IP=192.168.31.157:5555

set ADB_CMD=adb
if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" (
    set "ADB_CMD=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
)

echo [1/6] Connecting to Jio STB (%TARGET_IP%)...
"%ADB_CMD%" connect %TARGET_IP%

echo [2/6] Re-enabling and restoring OEM TV Launcher...
"%ADB_CMD%" -s %TARGET_IP% shell pm enable com.gathin.tvhome
"%ADB_CMD%" -s %TARGET_IP% shell cmd package set-home-activity com.gathin.tvhome/com.gathin.tvhome.MainActivity

echo [3/6] Clearing accessibility overlays...
"%ADB_CMD%" -s %TARGET_IP% shell settings put secure enabled_accessibility_services null

echo [4/6] Reverting global freeform flags...
"%ADB_CMD%" -s %TARGET_IP% shell settings put global enable_freeform_support 0
"%ADB_CMD%" -s %TARGET_IP% shell settings put global force_resizable_activities 0

echo [5/6] Resetting display density & size...
"%ADB_CMD%" -s %TARGET_IP% shell wm density reset
"%ADB_CMD%" -s %TARGET_IP% shell wm size reset

echo [6/6] Rebooting STB to stock configuration...
"%ADB_CMD%" -s %TARGET_IP% reboot

echo ========================================================
echo Rollback completed. Jio STB is returning to stock TV OS.
echo ========================================================
pause
