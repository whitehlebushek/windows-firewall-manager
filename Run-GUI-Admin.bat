@echo off
title Windows Firewall Manager - GUI
:: Launch GUI with administrator rights (UAC prompt)
powershell -NoProfile -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -STA -ExecutionPolicy Bypass -File \"%~dp0FirewallManager.Gui.ps1\"'"
