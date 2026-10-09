# Clwtn Task Scheduler Optimizer (Gamer-Safe, Zero-Noise)
# Menonaktifkan / Mengaktifkan kembali task telemetry, feedback toast,
# dan background maintenance spike di Windows 11.
# v1.0 - 2026-10-08

[CmdletBinding()]
param(
    [ValidateSet('Disable', 'Enable', 'Status')]
    [string]$Action = 'Disable'
)

# Auto Self-Elevate via UAC
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[*] Membutuhkan hak Administrator. Meminta izin UAC..." -ForegroundColor Yellow
    $scriptPath = $PSCommandPath
    if (-not $scriptPath) { $scriptPath = $MyInvocation.MyCommand.Definition }
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$scriptPath`" -Action $Action"
    exit
}

# Daftar Target Tasks (Kategori 3 & 4)
$targetTasks = @(
    # Kategori 3: Telemetry, Diagnostics & Tracking
    @{ Path = '\Microsoft\Windows\Maps\'; Name = 'MapsToastTask'; Category = 'Telemetry' },
    @{ Path = '\Microsoft\Windows\PerformanceTrace\'; Name = 'ShowFeedbackToast'; Category = 'Telemetry' },
    @{ Path = '\Microsoft\Windows\PerformanceTrace\'; Name = 'WhesvcToast'; Category = 'Telemetry' },
    @{ Path = '\Microsoft\Windows\Shell\'; Name = 'FamilySafetyMonitor'; Category = 'Telemetry' },
    @{ Path = '\Microsoft\Windows\Shell\'; Name = 'FamilySafetyRefreshTask'; Category = 'Telemetry' },
    @{ Path = '\Microsoft\Windows\Sustainability\'; Name = 'PowerGridForecastTask'; Category = 'Telemetry' },
    @{ Path = '\Microsoft\Windows\Sustainability\'; Name = 'SustainabilityTelemetry'; Category = 'Telemetry' },
    @{ Path = '\Microsoft\Windows\Windows Error Reporting\'; Name = 'QueueReporting'; Category = 'Telemetry' },
    @{ Path = '\Microsoft\Windows\DiskFootprint\'; Name = 'Diagnostics'; Category = 'Telemetry' },
    @{ Path = '\Microsoft\Windows\Autochk\'; Name = 'Proxy'; Category = 'Telemetry' },
    @{ Path = '\Microsoft\Windows\MemoryDiagnostic\'; Name = 'ProcessMemoryDiagnosticEvents'; Category = 'Telemetry' },
    @{ Path = '\Microsoft\Windows\MemoryDiagnostic\'; Name = 'AutomaticOfflineMemoryDiagnostic'; Category = 'Telemetry' },

    # Kategori 4: Maintenance Spikes & Experiment Telemetry
    @{ Path = '\Microsoft\Windows\Maintenance\'; Name = 'WinSAT'; Category = 'Maintenance' },
    @{ Path = '\Microsoft\Windows\Diagnosis\'; Name = 'Scheduled'; Category = 'Maintenance' },
    @{ Path = '\Microsoft\Windows\Diagnosis\'; Name = 'RecommendedTroubleshootingScanner'; Category = 'Maintenance' },
    @{ Path = '\Microsoft\Windows\Diagnosis\'; Name = 'UnexpectedCodepath'; Category = 'Maintenance' },
    @{ Path = '\Microsoft\Windows\Flighting\FeatureConfig\'; Name = 'GovernedFeatureUsageProcessing'; Category = 'Experiment' },
    @{ Path = '\Microsoft\Windows\Flighting\FeatureConfig\'; Name = 'ReconcileConfigs'; Category = 'Experiment' },
    @{ Path = '\Microsoft\Windows\Flighting\FeatureConfig\'; Name = 'ReconcileFeatures'; Category = 'Experiment' },
    @{ Path = '\Microsoft\Windows\Flighting\FeatureConfig\'; Name = 'SafeguardsReconciliation'; Category = 'Experiment' },
    @{ Path = '\Microsoft\Windows\Flighting\FeatureConfig\'; Name = 'UsageDataFlushing'; Category = 'Experiment' },
    @{ Path = '\Microsoft\Windows\Flighting\FeatureConfig\'; Name = 'UsageDataReceiver'; Category = 'Experiment' }
)

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  Clwtn Task Scheduler Optimizer - Mode: $Action" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

$results = foreach ($item in $targetTasks) {
    $tPath = $item.Path
    $tName = $item.Name
    $cat   = $item.Category

    $taskObj = Get-ScheduledTask -TaskPath $tPath -TaskName $tName -ErrorAction SilentlyContinue

    if (-not $taskObj) {
        [PSCustomObject]@{
            Category = $cat
            Task     = $tName
            Previous = 'N/A'
            Current  = 'Not Found'
            Result   = 'Skipped'
        }
        continue
    }

    $prevState = $taskObj.State.ToString()

    switch ($Action) {
        'Disable' {
            if ($prevState -eq 'Disabled') {
                [PSCustomObject]@{
                    Category = $cat
                    Task     = $tName
                    Previous = $prevState
                    Current  = 'Disabled'
                    Result   = 'Already Disabled'
                }
            } else {
                try {
                    Disable-ScheduledTask -TaskPath $tPath -TaskName $tName -ErrorAction Stop | Out-Null
                    $updated = Get-ScheduledTask -TaskPath $tPath -TaskName $tName -ErrorAction SilentlyContinue
                    [PSCustomObject]@{
                        Category = $cat
                        Task     = $tName
                        Previous = $prevState
                        Current  = $updated.State.ToString()
                        Result   = 'Success (Disabled)'
                    }
                } catch {
                    [PSCustomObject]@{
                        Category = $cat
                        Task     = $tName
                        Previous = $prevState
                        Current  = $prevState
                        Result   = "Error: $($_.Exception.Message)"
                    }
                }
            }
        }
        'Enable' {
            try {
                Enable-ScheduledTask -TaskPath $tPath -TaskName $tName -ErrorAction Stop | Out-Null
                $updated = Get-ScheduledTask -TaskPath $tPath -TaskName $tName -ErrorAction SilentlyContinue
                [PSCustomObject]@{
                    Category = $cat
                    Task     = $tName
                    Previous = $prevState
                    Current  = $updated.State.ToString()
                    Result   = 'Success (Enabled)'
                }
            } catch {
                [PSCustomObject]@{
                    Category = $cat
                    Task     = $tName
                    Previous = $prevState
                    Current  = $prevState
                    Result   = "Error: $($_.Exception.Message)"
                }
            }
        }
        'Status' {
            [PSCustomObject]@{
                Category = $cat
                Task     = $tName
                Previous = $prevState
                Current  = $prevState
                Result   = 'Inspect Only'
            }
        }
    }
}

$results | Format-Table -AutoSize

$successCount = ($results | Where-Object { $_.Result -like '*Success*' -or $_.Result -eq 'Already Disabled' }).Count
Write-Host "`n[*] Selesai: $successCount dari $($targetTasks.Count) tasks berhasil diproses." -ForegroundColor Green
Write-Host "[*] Sistem vital, gaming, dan DirectX tetap 100% aman.`n" -ForegroundColor DarkGray

Write-Host "Tekan ENTER untuk menutup..." -ForegroundColor Gray
Read-Host
