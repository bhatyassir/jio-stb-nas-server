# Registers a scheduled task: run the mounter at logon and every 2 minutes (hidden, current user).
$vbs = Join-Path $PSScriptRoot 'nas_mount.vbs'
$a = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument "`"$vbs`""
$t = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$t.Repetition = (New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 2)).Repetition
$s = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName 'JioNasMount' -Action $a -Trigger $t -Settings $s -Force
Start-ScheduledTask JioNasMount
# Remove with: Unregister-ScheduledTask JioNasMount -Confirm:$false
