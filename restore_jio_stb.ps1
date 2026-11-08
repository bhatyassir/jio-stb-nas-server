# Jio STB Emergency Rollback Script (PowerShell)
$targetIp = "192.168.31.157:5555"
$adbPath = "adb"
if (Test-Path "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe") {
    $adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
}

Write-Host "Connecting to Jio STB ($targetIp)..." -ForegroundColor Cyan
& $adbPath connect $targetIp | Out-Null

Write-Host "Restoring OEM TV Launcher (com.gathin.tvhome)..." -ForegroundColor Yellow
& $adbPath -s $targetIp shell pm enable com.gathin.tvhome
& $adbPath -s $targetIp shell cmd package set-home-activity com.gathin.tvhome/com.gathin.tvhome.MainActivity

Write-Host "Disabling custom accessibility services..." -ForegroundColor Yellow
& $adbPath -s $targetIp shell settings put secure enabled_accessibility_services null

Write-Host "Reverting global freeform flags..." -ForegroundColor Yellow
& $adbPath -s $targetIp shell settings put global enable_freeform_support 0
& $adbPath -s $targetIp shell settings put global force_resizable_activities 0

Write-Host "Resetting WindowManager display density..." -ForegroundColor Yellow
& $adbPath -s $targetIp shell wm density reset
& $adbPath -s $targetIp shell wm size reset

Write-Host "Rebooting STB..." -ForegroundColor Green
& $adbPath -s $targetIp reboot

Write-Host "Stock TV interface restored successfully." -ForegroundColor Green
