@echo off
title Firewall Manager GUI
powershell -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0FirewallManager.Gui.ps1"
if errorlevel 1 pause
