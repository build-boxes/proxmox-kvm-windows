$ErrorActionPreference = "Stop"

if ($env:PACKER_ENABLE_OPENSSH -notmatch "^(?i:true|1|yes)$") {
    Write-Host "Skipping OpenSSH installation."
    exit 0
}

$capabilities = Get-WindowsCapability -Online | Where-Object { $_.Name -like "OpenSSH*" }
$serverCapability = $capabilities | Where-Object { $_.Name -like "OpenSSH.Server*" } | Select-Object -First 1
$clientCapability = $capabilities | Where-Object { $_.Name -like "OpenSSH.Client*" } | Select-Object -First 1

if ($clientCapability -and $clientCapability.State -ne "Installed") {
    Add-WindowsCapability -Online -Name $clientCapability.Name | Out-Null
}

if ($serverCapability -and $serverCapability.State -ne "Installed") {
    Add-WindowsCapability -Online -Name $serverCapability.Name | Out-Null
}

Set-Service -Name sshd -StartupType Automatic
Set-Service -Name ssh-agent -StartupType Automatic

if (-not (Get-NetFirewallRule -DisplayName "SSH Port" -ErrorAction SilentlyContinue)) {
    netsh advfirewall firewall add rule name="SSH Port" dir=in action=allow protocol=TCP localport=22 remoteip=any | Out-Null
}

Start-Service sshd