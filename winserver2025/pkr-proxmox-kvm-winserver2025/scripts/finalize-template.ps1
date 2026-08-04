param(
    [string]$LogRoot = "C:\packer_build_logs"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -Path $LogRoot)) {
    New-Item -Path $LogRoot -ItemType Directory -Force | Out-Null
}

$logFile = Join-Path $LogRoot "finalize-template.log"
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $line = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-ddTHH:mm:ss"), $Level, $Message
    Write-Output $line
    Add-Content -Path $logFile -Value $line
}

Write-Log "Starting template finalization."

if ($env:PACKER_ENABLE_SYSPREP_APPX_WORKAROUND -match "^(?i:true|1|yes)$") {
    Write-Log "Applying sysprep Appx workaround."
    Remove-AppxPackage -Package "Microsoft.WidgetsPlatformRuntime_1.6.1.0_x64__8wekyb3d8bbwe" -AllUsers -ErrorAction SilentlyContinue
}

if ($env:PACKER_ENABLE_IPCONFIG_RELEASE_BEFORE_SYSPREP -match "^(?i:true|1|yes)$") {
    Write-Log "Releasing IP configuration before sysprep."
    ipconfig /release | Out-Host
}

Get-ChildItem -Path $env:TEMP -Filter "*.msi" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
Write-Log "Removed temporary MSI files from TEMP."

$sysprep = Join-Path $env:WINDIR "System32\Sysprep\Sysprep.exe"
if (-not (Test-Path $sysprep)) {
    Write-Log "Unable to locate sysprep.exe." "ERROR"
    throw "Unable to locate sysprep.exe"
}

Write-Log "Launching sysprep with /generalize /oobe /shutdown /quiet."
& $sysprep /generalize /oobe /shutdown /quiet