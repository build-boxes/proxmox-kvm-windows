$ErrorActionPreference = "Stop"

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
        $virtioMsiPath = Join-Path $env:TEMP "virtio-win-gt-x64.msi"
        Invoke-WebRequest -Uri $env:PACKER_VIRTIO_GUEST_TOOLS_URL -OutFile $virtioMsiPath
        Start-Process msiexec.exe -ArgumentList "/i `"$virtioMsiPath`" /qn /norestart" -Wait -NoNewWindow
        Remove-Item -Path $virtioMsiPath -Force -ErrorAction SilentlyContinue
    }
}

$qemuGuestAgentMsi = Find-InstallerOnCd -RelativePaths @(
    "guest-agent\qemu-ga-x86_64.msi",
    "guest-agent\qemu-ga-i386.msi"
)

if (-not $qemuGuestAgentMsi) {
    throw "Unable to locate the qemu guest agent installer on any attached media."
}

Start-Process msiexec.exe -ArgumentList "/i `"$qemuGuestAgentMsi`" /qn /norestart" -Wait -NoNewWindow

Set-Service -Name "QEMU-GA" -StartupType Automatic
Start-Service -Name "QEMU-GA"
Get-Service -Name "QEMU-GA"