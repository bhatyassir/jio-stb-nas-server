# Helper script to interact with Jio STB
param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$AdbArgs
)

$adbPath = "C:\Users\Bhat Tajamul\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$device = "192.168.31.157:5555"

# Ensure connected
& $adbPath connect $device | Out-Null

if ($AdbArgs.Count -eq 0) {
    & $adbPath -s $device shell
} else {
    & $adbPath -s $device @AdbArgs
}
