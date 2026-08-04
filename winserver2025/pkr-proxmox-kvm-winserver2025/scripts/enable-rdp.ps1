$ErrorActionPreference = "Stop"

if ($env:PACKER_ENABLE_RDP -notmatch "^(?i:true|1|yes)$") {
    Write-Host "Skipping RDP enablement."
    exit 0
}

Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"