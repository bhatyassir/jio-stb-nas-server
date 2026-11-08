@echo off
title Jio STB USB NAS - Windows 11 Network Drive Mapper
echo ===============================================================
echo       Mapping Jio STB External USB Drive & NAS Shares
echo ===============================================================
echo Device IP: 192.168.31.199 ^| SMB Port: 4445 ^| User: admin
echo.

echo Mapping Drive Z: to External USB Drive (\\192.168.31.199\External_USB)...
net use Z: /delete /y >nul 2>&1
net use Z: \\192.168.31.199\External_USB 123456 /USER:admin /TCPPORT:4445 /PERSISTENT:YES
if %errorlevel% equ 0 (
    echo [SUCCESS] External USB Drive mounted to Drive Z:
) else (
    echo [NOTICE] External USB Drive not detected, falling back to Jio_NAS...
    net use Z: \\192.168.31.199\Jio_NAS 123456 /USER:admin /TCPPORT:4445 /PERSISTENT:YES
)

echo.
echo Mapping Drive Y: to Internal Storage (\\192.168.31.199\Internal_Storage)...
net use Y: /delete /y >nul 2>&1
net use Y: \\192.168.31.199\Internal_Storage 123456 /USER:admin /TCPPORT:4445 /PERSISTENT:YES >nul 2>&1

echo.
echo Opening Drive Z: in Windows Explorer...
explorer.exe Z:\

echo.
echo ===============================================================
echo Web Interface also available at: http://192.168.31.199:8080
echo User: admin ^| Pass: JioNAS@2026!Admin
echo.
echo Emby Media Server Web UI: http://192.168.31.199:8096
echo ===============================================================
echo.
pause
