# Copy to nas_config.ps1 (gitignored) and edit.
$Ip   = '192.168.X.X'            # STB static IP (reserve it in your router)
$Mac  = 'aa-bb-cc-dd-ee-ff'      # STB Wi-Fi MAC, used to find the STB if the IP changes
$Port = 4445                     # Samba port on the STB
$User = 'admin'
$Pass = 'CHANGE_ME'
