$ErrorActionPreference = "Stop"

if ($env:PACKER_ENABLE_SYSPREP_APPX_WORKAROUND -match "^(?i:true|1|yes)$") {
    Remove-AppxPackage -Package "Microsoft.WidgetsPlatformRuntime_1.6.1.0_x64__8wekyb3d8bbwe" -AllUsers -ErrorAction SilentlyContinue
}

if ($env:PACKER_ENABLE_IPCONFIG_RELEASE_BEFORE_SYSPREP -match "^(?i:true|1|yes)$") {
    ipconfig /release | Out-Host
}

Get-ChildItem -Path $env:TEMP -Filter "*.msi" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

$sysprep = Join-Path $env:WINDIR "System32\Sysprep\Sysprep.exe"
if (-not (Test-Path $sysprep)) {
    throw "Unable to locate sysprep.exe"
}

& $sysprep /generalize /oobe /shutdown /quiet