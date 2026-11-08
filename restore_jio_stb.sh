#!/usr/bin/env bash
# Jio STB Emergency Restore Script
TARGET_IP="192.168.31.157:5555"

echo "Connecting to Jio STB ($TARGET_IP)..."
adb connect "$TARGET_IP"

echo "Restoring OEM TV Launcher..."
adb -s "$TARGET_IP" shell pm enable com.gathin.tvhome
adb -s "$TARGET_IP" shell cmd package set-home-activity com.gathin.tvhome/com.gathin.tvhome.MainActivity

echo "Disabling Smart Dock Accessibility..."
adb -s "$TARGET_IP" shell settings put secure enabled_accessibility_services null

echo "Reverting Global Freeform & Resizable Multi-Window Flags..."
adb -s "$TARGET_IP" shell settings put global enable_freeform_support 0
adb -s "$TARGET_IP" shell settings put global force_resizable_activities 0

echo "Resetting Display Density and Geometry..."
adb -s "$TARGET_IP" shell wm density reset
adb -s "$TARGET_IP" shell wm size reset

echo "Rebooting STB to stock environment..."
adb -s "$TARGET_IP" reboot

echo "Rollback sequence completed successfully."
