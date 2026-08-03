param(
    [string]$LogRoot = "C:\packer_build_logs"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -Path $LogRoot)) {
    New-Item -Path $LogRoot -ItemType Directory -Force | Out-Null
}

$logFile = Join-Path $LogRoot "install-virtio-guest-tools.log"
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $line = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-ddTHH:mm:ss"), $Level, $Message
    Write-Output $line
    Add-Content -Path $logFile -Value $line
}

function ConvertTo-Bool {
    param([string]$Value)
    return $Value -match "^(?i:true|1|yes)$"
}

function Find-InstallerOnCd {
    param([string[]]$RelativePaths)

    $volumes = Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveLetter }
    foreach ($volume in $volumes) {
        foreach ($relativePath in $RelativePaths) {
            $candidate = "{0}:\{1}" -f $volume.DriveLetter, $relativePath
            if (Test-Path $candidate) {
                return $candidate
            }
        }
    }

    return $null
}

if (ConvertTo-Bool $env:PACKER_ENABLE_VIRTIO_GUEST_TOOLS) {
    if (-not [string]::IsNullOrWhiteSpace($env:PACKER_VIRTIO_GUEST_TOOLS_URL)) {
        Write-Log "Downloading VirtIO guest tools MSI from configured URL."
        $virtioMsiPath = Join-Path $env:TEMP "virtio-win-gt-x64.msi"
        Invoke-WebRequest -Uri $env:PACKER_VIRTIO_GUEST_TOOLS_URL -OutFile $virtioMsiPath
        Start-Process msiexec.exe -ArgumentList "/i `"$virtioMsiPath`" /qn /norestart" -Wait -NoNewWindow
        Remove-Item -Path $virtioMsiPath -Force -ErrorAction SilentlyContinue
        Write-Log "VirtIO guest tools MSI installed."
    }
}

Write-Log "Searching attached media for QEMU guest agent MSI."
$qemuGuestAgentMsi = Find-InstallerOnCd -RelativePaths @(
    "guest-agent\qemu-ga-x86_64.msi",
    "guest-agent\qemu-ga-i386.msi"
)

if (-not $qemuGuestAgentMsi) {
    Write-Log "Unable to locate QEMU guest agent installer on attached media." "ERROR"
    throw "Unable to locate the qemu guest agent installer on any attached media."
}

Write-Log "Installing QEMU guest agent from $qemuGuestAgentMsi."
Start-Process msiexec.exe -ArgumentList "/i `"$qemuGuestAgentMsi`" /qn /norestart" -Wait -NoNewWindow

Set-Service -Name "QEMU-GA" -StartupType Automatic
Start-Service -Name "QEMU-GA"
Get-Service -Name "QEMU-GA"
Write-Log "QEMU guest agent installation and startup complete."