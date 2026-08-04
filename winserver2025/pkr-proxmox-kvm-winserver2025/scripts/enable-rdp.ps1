param(
    [string]$LogRoot = "C:\packer_build_logs"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -Path $LogRoot)) {
    New-Item -Path $LogRoot -ItemType Directory -Force | Out-Null
}

$logFile = Join-Path $LogRoot "enable-rdp.log"
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $line = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-ddTHH:mm:ss"), $Level, $Message
    Write-Output $line
    Add-Content -Path $logFile -Value $line
}

if ($env:PACKER_ENABLE_RDP -notmatch "^(?i:true|1|yes)$") {
    Write-Log "Skipping RDP enablement because PACKER_ENABLE_RDP is disabled."
    return
}

Write-Log "Enabling Remote Desktop access and firewall rules."
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Write-Log "Remote Desktop has been enabled successfully."