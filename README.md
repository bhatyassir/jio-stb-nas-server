> **DISCLAIMER:** 
> This project has been tested only on the **Jio JMSC200A Set-Top Box** running **Android 11 / JioOS**.
>
> I have not tested it on other Jio STB models or hardware revisions. Compatibility with other devices is not guaranteed.
>
> **Try it at your own risk.** Commands and configurations may behave differently depending on your device, firmware, Android version and hardware configuration. Always understand what a command does before executing it.

---

# Auto-Mounting USB NAS & 24/7 Emby Media Server for Android TV / Jio STB

Turn an underpowered or idle Android TV Set-Top Box (Amlogic S905X3, Android 9–11) into a high-performance, self-healing Home NAS and 24/7 Emby 4K Media Server that runs completely in the background without affecting normal TV viewing.

---

## Key Features

* **Zero-Touch Dynamic USB Auto-Mounter:** Automatically monitors `/proc/mounts` every 10 seconds. When an external HDD/SSD/Flash drive (NTFS, exFAT, ext4, FAT32) is plugged in, the system dynamically discovers its UUID, updates Samba configurations on the fly, and exports the volume across the network.
* **Self-Healing Background Daemons:** A supervisor watchdog monitors the Samba (`smbd`) and FileBrowser processes. If either is closed or killed by Android's low-memory killer, the watchdog automatically respawns them within 10 seconds.
* **Hardware Reboot Persistence (JioNasAutoBoot):** A lightweight native broadcast companion app intercepts `BOOT_COMPLETED` and `LOCKED_BOOT_COMPLETED`, starts Termux in the background, acquires persistent wake-locks, launches all daemons, and returns focus to the stock TV launcher in 4 seconds.
* **Cross-Platform Access:**
  * **Windows:** Native mapped network drive (`Z:\`) over SMB3.
  * **macOS / iOS / Android:** Native SMB file sharing & mobile apps.
  * **Universal Web Interface:** FileBrowser UI on port `8080`.
  * **4K Media Streaming:** Standalone Emby Server on port `8096`.

---

## ⚠️ Network Speed Note: Why 5 GHz Wi-Fi Outperforms Physical Ethernet

The physical RJ45 Ethernet port on most Android TV STBs (including the Jio STB JMSC200A) is hardwired to an internal **100 Mbps Fast Ethernet PHY (100BASE-TX)**, capping local file transfers to **~11.5 MB/s**.

However, the internal Wi-Fi chip (**Realtek RTL8822CS**) is a **2×2 MIMO Dual-Band 802.11ac (Wi-Fi 5)** controller capable of link speeds up to **866 Mbps**.

* **Ethernet (LAN):** Capped at ~11.5 MB/s (~94 Mbps).
* **5 GHz Wi-Fi:** Delivers real-world speeds of ~40–55 MB/s (350–450 Mbps).

> **Recommendation:** For 4K media streaming and rapid file transfers, connect the STB to a 5 GHz Wi-Fi network or use a USB 3.0 Gigabit Ethernet adapter.

---

## 3. Master AI Agent Prompt (Copy & Paste for Autonomous Setup)

Anyone can copy and paste the following prompt into an autonomous coding/system agent (such as Antigravity, Claude Code, etc.) to set up this entire architecture from scratch:

```markdown
You are an expert embedded Linux and Android engineer. Your task is to transform a connected Android TV Set-Top Box (via ADB IP 192.168.X.X:5555) into an auto-mounting External USB NAS and 24/7 Media Server, with zero touch required on boot and zero disruption to the TV experience.

Follow these strict technical specifications:

### Phase 1: Environment & Architecture Verification
* Connect via `adb connect <STB_IP>:5555` and verify architecture (`getprop ro.product.cpu.abi` - typically `armeabi-v7a`).
* Verify Android version (typically Android 9–11) and display state (`dumpsys power`).
* Check network link speeds: determine if the physical Ethernet is 100 Mbps and confirm the Wi-Fi chipset (e.g. RTL8822CS 2x2 AC 867 Mbps). Strongly prioritize 5 GHz Wi-Fi for maximum NAS throughput.

### Phase 2: Termux Engine Deployment & Privileges
* Sideload a compatible Termux APK (e.g. `termux-v7a.apk` v0.118+).
* Escalate system permissions via ADB:
  * `appops set com.termux MANAGE_EXTERNAL_STORAGE allow`
  * `pm grant com.termux android.permission.READ_EXTERNAL_STORAGE`
  * `pm grant com.termux android.permission.WRITE_EXTERNAL_STORAGE`
  * `cmd deviceidle whitelist +com.termux`
* In `~/.termux/termux.properties`, enable `allow-external-apps = true`.

### Phase 3: Lightweight NAS Stack Installation
* **Install and configure Samba SMB3:**
  * Run Samba in non-root user mode on TCP port `4445` (exporting `[External_USB]`, `[Jio_NAS]`, `[Internal_Storage]`).
  * Configure credentials (`admin` / `123456`), enable wide symlinks, and set `ntlm auth = yes`.
* **Install static 32-bit ARM FileBrowser binary:**
  * Configure to listen on port `8080` with database at `~/.config/filebrowser.db`.
  * Set root directory to `/storage` with `--followExternalSymlinks`.
  * Create admin account (`admin` / `JioNAS@2026!Admin`).
* **Deploy Emby Media Server:**
  * Sideload official ARMv7 `embyserver.apk`.
  * Grant `MANAGE_EXTERNAL_STORAGE` and add to `deviceidle` whitelist.
  * Verify listening port `8096`.

### Phase 4: Dynamic Dynamic USB Mounter & Process Watchdog
Deploy a shell watchdog script (`~/usb_nas_watchdog.sh`) running an infinite loop every 10 seconds:
* Scan `/proc/mounts` for active USB storage volumes (`/storage/[0-9A-Za-z_-]*`).
* Clean broken symlinks under `$HOME/NAS_Root/External_Drives`.
* Create symlinks pointing to newly detected external volumes.
* If volume mount paths change, dynamically update Samba's `smb.conf` and issue `pkill -HUP smbd`.
* **Self-Healing Process Watchdog:** Check `pgrep smbd` and `pgrep filebrowser`. If either process died, automatically restart it.

### Phase 5: Zero-Touch Hardware Boot Auto-Launch Companion App
Build, sign, and install a dedicated native companion APK (`com.stb.nas.autostart`):
* In `AndroidManifest.xml`, register a `BroadcastReceiver` listening for:
  * `android.intent.action.BOOT_COMPLETED`
  * `android.intent.action.LOCKED_BOOT_COMPLETED`
  * `android.intent.action.QUICKBOOT_POWERON`
* **Permissions required:**
  * `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK`, `FOREGROUND_SERVICE`, `SYSTEM_ALERT_WINDOW`, `QUERY_ALL_PACKAGES`, and `com.termux.permission.RUN_COMMAND`.
* **In receiver:**
  * Dispatches `com.termux.RUN_COMMAND` intent to `com.termux/.app.RunCommandService` running `start_nas_services.sh` in the background.
  * Triggers Termux wake lock (`termux-wake-lock`).
  * Automatically returns focus to the native TV Home Launcher (`Intent.CATEGORY_HOME`) after 4 seconds so the TV interface remains completely clean and undisturbed.
* Launch once after installation to transition package state out of `FLAG_STOPPED`.

### Phase 6: End-to-End Verification
* Execute a cold reboot (`adb reboot`).
* Verify all ports are listening after boot without manual touch:
  * **SMB:** `Test-NetConnection -Port 4445 -> True`
  * **Web UI:** `Test-NetConnection -Port 8080 -> True`
  * **Emby:** `Test-NetConnection -Port 8096 -> True`
* Verify remote network drive mapping on client PC (`net use Z: \\<IP>\External_USB ...`).
```
