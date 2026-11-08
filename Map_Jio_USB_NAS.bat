@echo off
rem One-shot manual mapper. Uses the same logic as the scheduled task.
rem Setup: copy windows\nas_config.example.ps1 to windows\nas_config.ps1 and edit it.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0windows\nas_mount.ps1"
net use
explorer.exe Z:\
pause
