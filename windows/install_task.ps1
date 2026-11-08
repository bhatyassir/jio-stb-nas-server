# Registers a scheduled task that runs the mounter at logon AND every 2 minutes (hidden, current user).
# Two triggers are needed: a repetition attached to an at-logon trigger only starts after the next logon.
$vbs = Join-Path $PSScriptRoot 'nas_mount.vbs'
$a  = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument "`"$vbs`""
$t1 = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$t2 = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 2) -RepetitionDuration (New-TimeSpan -Days 9999)
$s  = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName 'JioNasMount' -Action $a -Trigger @($t1, $t2) -Settings $s -Force
Start-ScheduledTask JioNasMount
# Remove with: Unregister-ScheduledTask JioNasMount -Confirm:$false
