param(
    [string]$LogRoot = "C:\packer_build_logs"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -Path $LogRoot)) {
    New-Item -Path $LogRoot -ItemType Directory -Force | Out-Null
}

$logFile = Join-Path $LogRoot "install-openssh.log"
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $line = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-ddTHH:mm:ss"), $Level, $Message
    Write-Output $line
    Add-Content -Path $logFile -Value $line
}

if ($env:PACKER_ENABLE_OPENSSH -notmatch "^(?i:true|1|yes)$") {
    Write-Log "Skipping OpenSSH installation because PACKER_ENABLE_OPENSSH is disabled."
    return
}

Write-Log "Discovering OpenSSH capabilities."
$capabilities = Get-WindowsCapability -Online | Where-Object { $_.Name -like "OpenSSH*" }
$serverCapability = $capabilities | Where-Object { $_.Name -like "OpenSSH.Server*" } | Select-Object -First 1
$clientCapability = $capabilities | Where-Object { $_.Name -like "OpenSSH.Client*" } | Select-Object -First 1

if ($clientCapability -and $clientCapability.State -ne "Installed") {
    Write-Log "Installing OpenSSH client capability: $($clientCapability.Name)."
    Add-WindowsCapability -Online -Name $clientCapability.Name | Out-Null
}

if ($serverCapability -and $serverCapability.State -ne "Installed") {
    Write-Log "Installing OpenSSH server capability: $($serverCapability.Name)."
    Add-WindowsCapability -Online -Name $serverCapability.Name | Out-Null
}

Set-Service -Name sshd -StartupType Automatic
Set-Service -Name ssh-agent -StartupType Automatic
Write-Log "Configured sshd and ssh-agent services to Automatic startup."

if (-not (Get-NetFirewallRule -DisplayName "SSH Port" -ErrorAction SilentlyContinue)) {
    netsh advfirewall firewall add rule name="SSH Port" dir=in action=allow protocol=TCP localport=22 remoteip=any | Out-Null
    Write-Log "Created firewall rule for TCP 22."
}

Start-Service sshd
Write-Log "OpenSSH server installation and startup complete."