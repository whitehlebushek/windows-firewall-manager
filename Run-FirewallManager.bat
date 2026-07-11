@echo off
title Windows Firewall Manager - CLI
:: Run console manager (requires Administrator)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0FirewallManager.ps1"
pause
