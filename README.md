# ðŸ›¡ï¸ Win11 Gamer-Safe Debloat & System Cleaner

[![Platform: Windows 11](https://img.shields.io/badge/Platform-Windows%2011%2024H2-0078D7.svg)](https://www.microsoft.com/)
[![Language: PowerShell](https://img.shields.io/badge/Language-PowerShell%207%20%2F%205.1-blue.svg)](https://microsoft.com/powershell)
[![Gaming: 100% Safe](https://img.shields.io/badge/Gaming-DirectX%20%26%20Anti--Cheat%20Safe-brightgreen.svg)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Surgical, safe Windows 11 debloating and multi-tier system maintenance engine. Designed specifically for high-performance esports and workstation rigs to eliminate background CPU spikes and idle telemetry without breaking Windows updates or gaming dependencies.

---

## ðŸš€ Key Modules

### 1. \debloat-tasks.ps1\ (22 Bloatware Tasks Safely Disabled)
- **Zero-Spike Execution**: Disables background telemetry (\MapsToastTask\, \ShowFeedbackToast\, \Diagnostics\, \WER\, \PowerGridForecastTask\) and flighting experiments (\WinSAT\, \ScheduledMaintenance\).
- **Gaming & OS Intact**: Never touches DirectX, .NET NGEN, Audio services, or Windows Update integrity.
- **Instant Rollback**: Modular commands supporting \-Action Disable\, \-Action Enable\, and \-Action Status\.

### 2. \clean-system.ps1\ (5-Tier Deep Engine)
- **Dev Caches**: NPM, PNPM, Yarn, Bun, Pip, Cargo, NuGet, Gradle, and Docker prune.
- **Multi-Browser**: Clean session cache for Chrome, Brave, Firefox, and Edge.
- **Kernel & Telemetry**: Eliminates crash memory dumps (\MEMORY.DMP\), WER reports, and CryptnetUrlCache.
- **Deep Windows Update**: Safely purges \SoftwareDistribution\Download\ and Delivery Optimization leftovers.

---

## ðŸ“œ License

MIT License. Built by [Clawtan](https://github.com/Clawtan).
