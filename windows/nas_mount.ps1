# Jio STB NAS self-healing mounter. Runs at logon and every 2 minutes.
$ErrorActionPreference = 'SilentlyContinue'
. (Join-Path $PSScriptRoot 'nas_config.ps1')   # defines $Ip $Mac $Port $User $Pass
$Log = Join-Path $PSScriptRoot 'nas.log'
function Log($m){ if((Test-Path $Log) -and (Get-Item $Log).Length -gt 200KB){ Remove-Item $Log }; Add-Content $Log ("{0:s} {1}" -f (Get-Date),$m) }
function Alive($ip){ try{ $c=New-Object Net.Sockets.TcpClient; $r=$c.BeginConnect($ip,$Port,$null,$null); $ok=$r.AsyncWaitHandle.WaitOne(1500); if($ok){$c.EndConnect($r)}; $c.Close(); return $ok }catch{ return $false } }

# single instance
$mutex = New-Object Threading.Mutex($false,'Global\JioNasMount'); if(-not $mutex.WaitOne(0)){ exit 0 }

if(-not (Alive $Ip)){
  $m = arp -a | Select-String $Mac
  if($m -and $m.Line -match '(\d+\.\d+\.\d+\.\d+)' -and (Alive $matches[1])){ $Ip=$matches[1]; Log "IP drift, using $Ip" }
  else { Log 'STB unreachable'; exit 1 }
}

cmdkey /add:$Ip /user:$User /pass:$Pass | Out-Null

function Mapped($letter){ (Get-PSDrive -Name $letter -PSProvider FileSystem).DisplayRoot }
function Healthy($letter){ (Test-Path "${letter}:\") }
$bs = [string][char]92   # backslash, built explicitly so the UNC prefix can't be mangled
function Map($letter,$share){ cmd /c "net use ${letter}: $bs$bs$Ip\$share $Pass /USER:$User /TCPPORT:$Port /PERSISTENT:NO >nul 2>&1"; return ($LASTEXITCODE -eq 0) }
function Unmap($letter){ cmd /c "net use ${letter}: /delete /y >nul 2>&1" }

# Z: prefer External_USB, fall back to Jio_NAS, and upgrade when the USB appears
$usbRoot = "$bs$bs$Ip\External_USB"
$z = Mapped 'Z'
if($z -eq $usbRoot -and (Healthy 'Z')){ }
else {
  if($z -and -not (Healthy 'Z')){ Unmap 'Z'; $z=$null }
  if($z -and $z -ne $usbRoot){
    # currently on fallback: probe whether USB share is available now
    if(Map 'W' 'External_USB'){ Unmap 'W'; Unmap 'Z'; Map 'Z' 'External_USB' | Out-Null; Log 'Z: upgraded to External_USB' }
  } elseif(-not $z){
    if(Map 'Z' 'External_USB'){ Log 'Z: -> External_USB' }
    elseif(Map 'Z' 'Jio_NAS'){ Log 'WARN Z: -> Jio_NAS (USB share unavailable, drive likely unmountable)' }
    else { Log 'ERROR could not map Z:' }
  }
}

# Y: internal storage
$y = Mapped 'Y'
if($y -and -not (Healthy 'Y')){ Unmap 'Y'; $y=$null }
if(-not $y){ if(Map 'Y' 'Internal_Storage'){ Log 'Y: mapped' } else { Log 'ERROR could not map Y:' } }
