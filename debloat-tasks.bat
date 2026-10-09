@echo off
:: Clwtn Scheduled Task Optimizer Runner
:: Klik kanan file ini -> "Run as administrator"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0debloat-tasks.ps1" -Action Disable
