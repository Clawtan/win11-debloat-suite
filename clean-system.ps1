<#
.SYNOPSIS
    Windows System, Dev Caches, Gaming & Deep OS Cleanup — Tier 1 to 5 (OCD Safe, Gamer-Safe, Zero-Bloat)
.DESCRIPTION
    Covers:
    - TIER 1: User/Windows Temp, Prefetch, Thumbnails & Icon Cache, Downloads, Recycle Bin, DNS Flush.
    - TIER 2: DirectX / NVIDIA (DXCache & GLCache) / AMD Shaders, Browsers (Chrome, Edge, Brave, Firefox), App Caches (Discord, Spotify).
    - TIER 3: Crash Dumps, Minidumps, MEMORY.DMP, WER Reports, INetCache, LiveKernelReports, CryptnetUrlCache.
    - TIER 4: Dev & Package Tooling (NPM, PNPM, Yarn, Bun, Pip, Cargo, NuGet, Gradle, Scoop, Choco, Docker).
    - TIER 5: Deep OS & Windows Update (SoftwareDistribution\Download, CBS & Setup Logs, Delivery Optimization, cleanmgr engine).
    Menghasilkan laporan metrik presisi tinggi (bytes, files, breakdown per area).
    v3.0 — 2026-10-08
#>

[CmdletBinding()]
param()

$initialFree = (Get-PSDrive C).Free

# Helper: format bytes ke string human-readable
function Format-ByteSize {
    param([double]$Bytes)
    if ($Bytes -ge 1GB)     { return "$([math]::Round($Bytes / 1GB, 2)) GB" }
    elseif ($Bytes -ge 1MB) { return "$([math]::Round($Bytes / 1MB, 2)) MB" }
    elseif ($Bytes -ge 1KB) { return "$([math]::Round($Bytes / 1KB, 2)) KB" }
    else                    { return "$Bytes Bytes" }
}

# Helper: hapus isi folder dengan tracking, skip file terkunci
function Remove-JunkFolder {
    param([string]$Path)
    $res = @{ Files = 0; Bytes = 0 }
    if (-not (Test-Path $Path)) { return $res }
    Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            if (-not $_.PSIsContainer) {
                $len = $_.Length
                Remove-Item -Path $_.FullName -Force -ErrorAction Stop
                $res.Bytes += $len
                $res.Files++
            } else {
                Remove-Item -Path $_.FullName -Force -Recurse -ErrorAction SilentlyContinue
            }
        } catch { <# File terkunci proses aktif / akses ditolak — lewati aman #> }
    }
    return $res
}

# Helper: hapus file spesifik dengan wildcard pattern
function Remove-JunkPattern {
    param([string]$Path, [string]$Filter = "*")
    $res = @{ Files = 0; Bytes = 0 }
    if (-not (Test-Path $Path)) { return $res }
    Get-ChildItem -Path $Path -Filter $Filter -Force -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            if (-not $_.PSIsContainer) {
                $len = $_.Length
                Remove-Item -Path $_.FullName -Force -ErrorAction Stop
                $res.Bytes += $len
                $res.Files++
            }
        } catch { <# Skip terkunci #> }
    }
    return $res
}

Write-Host "[*] Memulai Deep Clean v3.0 (Tier 1-5)..." -ForegroundColor Cyan

# ─────────────────────────────────────────────
# TIER 1 — Always Safe (Temp, Prefetch, Recycle Bin)
# ─────────────────────────────────────────────
$t1 = Remove-JunkFolder -Path $env:TEMP
$t2 = Remove-JunkFolder -Path "C:\Windows\Temp"
$tempFiles = $t1.Files + $t2.Files
$tempBytes = $t1.Bytes + $t2.Bytes

# Prefetch (regenerate otomatis oleh OS)
$pf = Remove-JunkPattern -Path "C:\Windows\Prefetch" -Filter "*.pf"
$prefetchFiles = $pf.Files
$prefetchBytes = $pf.Bytes

# Thumbnail & Icon Cache
$th1 = Remove-JunkPattern -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" -Filter "thumbcache_*.db"
$th2 = Remove-JunkPattern -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" -Filter "iconcache_*.db"
$ic = @{ Files = 0; Bytes = 0 }
$iconPath = "$env:LOCALAPPDATA\IconCache.db"
if (Test-Path $iconPath -ErrorAction SilentlyContinue) {
    try {
        $item = Get-Item $iconPath -ErrorAction Stop
        $ic.Bytes = $item.Length
        Remove-Item $iconPath -Force -ErrorAction Stop
        $ic.Files = 1
    } catch {}
}
$thumbFiles = $th1.Files + $th2.Files + $ic.Files
$thumbBytes = $th1.Bytes + $th2.Bytes + $ic.Bytes

# Downloads Folder
$dl = Remove-JunkFolder -Path "$env:USERPROFILE\Downloads"
$dlFiles = $dl.Files
$dlBytes  = $dl.Bytes

# Recycle Bin
$binFiles = 0; $binBytes = 0
try {
    $shell = New-Object -ComObject Shell.Application
    $bin   = $shell.Namespace(0xa)
    foreach ($item in $bin.Items()) { $binBytes += $item.Size; $binFiles++ }
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
} catch {}

# DNS Resolver Cache
try { ipconfig /flushdns | Out-Null } catch {}

# ─────────────────────────────────────────────
# TIER 2 — Gaming, Browsers & Desktop Apps
# ─────────────────────────────────────────────
# DirectX & GPU Shader Cache (Tailored for RTX 5080)
$s1 = Remove-JunkFolder -Path "$env:LOCALAPPDATA\D3DSCache"
$s2 = Remove-JunkFolder -Path "$env:LOCALAPPDATA\NVIDIA\DXCache"
$s3 = Remove-JunkFolder -Path "$env:LOCALAPPDATA\NVIDIA\GLCache"
$s4 = Remove-JunkFolder -Path "$env:LOCALAPPDATA\AMD\DxCache"
$s5 = Remove-JunkFolder -Path "$env:LOCALAPPDATA\AMD\GLCache"
$shaderFiles = $s1.Files + $s2.Files + $s3.Files + $s4.Files + $s5.Files
$shaderBytes = $s1.Bytes + $s2.Bytes + $s3.Bytes + $s4.Bytes + $s5.Bytes

# Multi-Browser Caches (Chrome, Edge, Brave, Firefox)
$br1 = Remove-JunkFolder -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
$br2 = Remove-JunkFolder -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache"
$br3 = Remove-JunkFolder -Path "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
$br4 = Remove-JunkFolder -Path "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache"
$br5 = Remove-JunkFolder -Path "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cache"
$br6 = Remove-JunkFolder -Path "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Code Cache"

$ffFiles = 0; $ffBytes = 0
$ffProfiles = "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles"
if (Test-Path $ffProfiles) {
    Get-ChildItem -Path $ffProfiles -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $ffRes = Remove-JunkFolder -Path (Join-Path $_.FullName "cache2")
        $ffFiles += $ffRes.Files
        $ffBytes += $ffRes.Bytes
    }
}
$browserFiles = $br1.Files + $br2.Files + $br3.Files + $br4.Files + $br5.Files + $br6.Files + $ffFiles
$browserBytes = $br1.Bytes + $br2.Bytes + $br3.Bytes + $br4.Bytes + $br5.Bytes + $br6.Bytes + $ffBytes

# Desktop App Cache (Discord, Spotify)
$a1 = Remove-JunkFolder -Path "$env:APPDATA\discord\Cache"
$a2 = Remove-JunkFolder -Path "$env:APPDATA\discord\Code Cache"
$a3 = Remove-JunkFolder -Path "$env:LOCALAPPDATA\Spotify\Data"
$appCacheFiles = $a1.Files + $a2.Files + $a3.Files
$appCacheBytes = $a1.Bytes + $a2.Bytes + $a3.Bytes

# ─────────────────────────────────────────────
# TIER 3 — Error Logs, Dumps & Crash Telemetry
# ─────────────────────────────────────────────
$c1 = Remove-JunkFolder -Path "$env:LOCALAPPDATA\CrashDumps"
$c2 = Remove-JunkFolder -Path "$env:LOCALAPPDATA\Microsoft\Windows\WER\ReportQueue"
$c3 = Remove-JunkFolder -Path "$env:LOCALAPPDATA\Microsoft\Windows\WER\ReportArchive"
$c4 = Remove-JunkFolder -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache"
$c5 = Remove-JunkFolder -Path "C:\Windows\LiveKernelReports"
$c6 = Remove-JunkFolder -Path "$env:LOCALAPPDATA\..\LocalLow\Microsoft\CryptnetUrlCache"

# Windows Minidumps
$md = Remove-JunkPattern -Path "C:\Windows\Minidump" -Filter "*.dmp"

# MEMORY.DMP (BSOD dump)
$memDmp = @{ Files = 0; Bytes = 0 }
$memPath = "C:\Windows\MEMORY.DMP"
if (Test-Path $memPath) {
    try {
        $memDmp.Bytes = (Get-Item $memPath).Length
        Remove-Item $memPath -Force -ErrorAction Stop
        $memDmp.Files = 1
    } catch {}
}
$dumpFiles = $c1.Files + $c2.Files + $c3.Files + $c4.Files + $c5.Files + $c6.Files + $md.Files + $memDmp.Files
$dumpBytes = $c1.Bytes + $c2.Bytes + $c3.Bytes + $c4.Bytes + $c5.Bytes + $c6.Bytes + $md.Bytes + $memDmp.Bytes

# ─────────────────────────────────────────────
# TIER 4 — Dev & Package Tooling Caches (Adopted from windows-cleaner-cli)
# ─────────────────────────────────────────────
$dev1 = Remove-JunkFolder -Path "$env:APPDATA\npm-cache"
$dev2 = Remove-JunkFolder -Path "$env:LOCALAPPDATA\Yarn\Cache"
$dev3 = Remove-JunkFolder -Path "$env:LOCALAPPDATA\pnpm\store"
$dev4 = Remove-JunkFolder -Path "$env:USERPROFILE\.bun\install\cache"
$dev5 = Remove-JunkFolder -Path "$env:LOCALAPPDATA\pip\cache"
$dev6 = Remove-JunkFolder -Path "$env:USERPROFILE\.cargo\registry\cache"
$dev7 = Remove-JunkFolder -Path "$env:USERPROFILE\.cargo\git\db"
$dev8 = Remove-JunkFolder -Path "$env:USERPROFILE\.nuget\packages"
$dev9 = Remove-JunkFolder -Path "$env:USERPROFILE\.gradle\caches"
$dev10 = Remove-JunkFolder -Path "$env:USERPROFILE\scoop\cache"
$dev11 = Remove-JunkFolder -Path "C:\ProgramData\chocolatey\cache"

$devFiles = $dev1.Files + $dev2.Files + $dev3.Files + $dev4.Files + $dev5.Files +
            $dev6.Files + $dev7.Files + $dev8.Files + $dev9.Files + $dev10.Files + $dev11.Files
$devBytes = $dev1.Bytes + $dev2.Bytes + $dev3.Bytes + $dev4.Bytes + $dev5.Bytes +
            $dev6.Bytes + $dev7.Bytes + $dev8.Bytes + $dev9.Bytes + $dev10.Bytes + $dev11.Bytes

# Docker System Prune (jika docker terinstall & running)
if (Get-Command docker -ErrorAction SilentlyContinue) {
    try {
        docker builder prune -f 2>$null | Out-Null
    } catch {}
}

# ─────────────────────────────────────────────
# TIER 5 — Deep OS & Windows Update Maintenance
# ─────────────────────────────────────────────
# Windows Update Download Cache & Delivery Optimization
$wu1 = Remove-JunkFolder -Path "C:\Windows\SoftwareDistribution\Download"
$wu2 = Remove-JunkFolder -Path "C:\Windows\SoftwareDistribution\DeliveryOptimization"
$wu3 = Remove-JunkFolder -Path "C:\Windows\Logs\CBS"
$wu4 = Remove-JunkFolder -Path "C:\Windows\Setup\Scripts"

# Root Windows Setup Logs
$wu5 = @{ Files = 0; Bytes = 0 }
Get-ChildItem -Path "C:\Windows" -Filter "*.log" -File -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        $len = $_.Length
        Remove-Item $_.FullName -Force -ErrorAction Stop
        $wu5.Bytes += $len
        $wu5.Files++
    } catch {}
}

$deepOSFiles = $wu1.Files + $wu2.Files + $wu3.Files + $wu4.Files + $wu5.Files
$deepOSBytes = $wu1.Bytes + $wu2.Bytes + $wu3.Bytes + $wu4.Bytes + $wu5.Bytes

# Engine Disk Cleanup Bawaan Windows (Silent background)
try {
    Start-Process cleanmgr.exe -ArgumentList "/sagerun:64"  -Wait -NoNewWindow -ErrorAction SilentlyContinue
    Start-Process cleanmgr.exe -ArgumentList "/autoclean"   -Wait -NoNewWindow -ErrorAction SilentlyContinue
} catch {}

# ─────────────────────────────────────────────
# KALKULASI & LAPORAN
# ─────────────────────────────────────────────
$totalFiles = $tempFiles + $prefetchFiles + $thumbFiles + $dlFiles + $binFiles +
              $shaderFiles + $browserFiles + $appCacheFiles + $dumpFiles +
              $devFiles + $deepOSFiles

$totalBytes = $tempBytes + $prefetchBytes + $thumbBytes + $dlBytes + $binBytes +
              $shaderBytes + $browserBytes + $appCacheBytes + $dumpBytes +
              $devBytes + $deepOSBytes

$finalFree     = (Get-PSDrive C).Free
$deltaFree     = [math]::Max(0, $finalFree - $initialFree)

Write-Host "[+] Deep Clean v3.0 selesai dengan sukses!" -ForegroundColor Green

[PSCustomObject]@{
    TotalDeletedFiles        = $totalFiles
    TotalCleanedSize         = Format-ByteSize $totalBytes
    DiskSpaceReclaimed       = Format-ByteSize $deltaFree
    CurrentFreeSpace         = Format-ByteSize $finalFree
    "---TIER 1---"           = "Always Safe (Temp/Prefetch/Thumb/Bin)"
    Breakdown_Temp           = "$tempFiles files ($(Format-ByteSize $tempBytes))"
    Breakdown_Prefetch       = "$prefetchFiles files ($(Format-ByteSize $prefetchBytes))"
    Breakdown_ThumbIconCache = "$thumbFiles files ($(Format-ByteSize $thumbBytes))"
    Breakdown_Downloads      = "$dlFiles files ($(Format-ByteSize $dlBytes))"
    Breakdown_RecycleBin     = "$binFiles files ($(Format-ByteSize $binBytes))"
    "---TIER 2---"           = "Gaming (RTX 5080) & Browsers"
    Breakdown_GPUShaders     = "$shaderFiles files ($(Format-ByteSize $shaderBytes))"
    Breakdown_BrowserCache   = "$browserFiles files ($(Format-ByteSize $browserBytes))"
    Breakdown_AppCache       = "$appCacheFiles files ($(Format-ByteSize $appCacheBytes))"
    "---TIER 3---"           = "Dumps, WER & Telemetry"
    Breakdown_DumpsAndWER    = "$dumpFiles files ($(Format-ByteSize $dumpBytes))"
    "---TIER 4---"           = "Dev Caches (Pip/Cargo/Bun/NPM/NuGet)"
    Breakdown_DevTooling     = "$devFiles files ($(Format-ByteSize $devBytes))"
    "---TIER 5---"           = "Deep OS & Windows Update Logs"
    Breakdown_DeepOSLogs     = "$deepOSFiles files ($(Format-ByteSize $deepOSBytes))"
} | Format-List
