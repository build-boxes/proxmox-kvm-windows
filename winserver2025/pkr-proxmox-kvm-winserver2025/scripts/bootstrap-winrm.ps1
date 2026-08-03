param(
    [int]$WinRMPort = 5986
)

$ErrorActionPreference = "Stop"
$logFolder = 'C:\packer_build_logs'
if (-not (Test-Path -Path $logFolder)) {
    Write-Host "Creating log folder at $logFolder..."
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}

Start-Transcript -Path (Join-Path $logFolder 'bootstrap-winrm.log') -Append -ErrorAction SilentlyContinue | Out-Null

Write-Host "Configuring WinRM HTTPS listener for Packer..."

Enable-PSRemoting -SkipNetworkProfileCheck -Force
Set-Service -Name WinRM -StartupType Automatic
Start-Service -Name WinRM

# Ensure core WinRM service settings expected by Packer are enabled.
Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $false
Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item -Path WSMan:\localhost\Service\Auth\Negotiate -Value $true
Set-Item -Path WSMan:\localhost\Service\Auth\Certificate -Value $true
Set-Item -Path WSMan:\localhost\Service\Auth\CredSSP -Value $false

$existingHttpsListener = Get-ChildItem -Path WSMan:\LocalHost\Listener -ErrorAction SilentlyContinue |
    Where-Object { $_.Keys -contains "Transport=HTTPS" }

if (-not $existingHttpsListener) {
    $hostname = $env:COMPUTERNAME
    $certificate = New-SelfSignedCertificate `
        -DnsName $hostname `
        -CertStoreLocation "Cert:\LocalMachine\My" `
        -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.1")

    New-Item -Path WSMan:\LocalHost\Listener `
        -Transport HTTPS `
        -Address * `
        -CertificateThumbPrint $certificate.Thumbprint `
        -Force | Out-Null
}

if (-not (Get-NetFirewallRule -Name "WinRM-HTTPS-Inbound" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule `
        -Name "WinRM-HTTPS-Inbound" `
        -DisplayName "Windows Remote Management (HTTPS-In)" `
        -Direction Inbound `
        -Action Allow `
        -Protocol TCP `
        -LocalPort $WinRMPort `
        -Profile Any | Out-Null
}

if (-not (Get-NetFirewallRule -Name "WinRM-HTTP-Inbound" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule `
        -Name "WinRM-HTTP-Inbound" `
        -DisplayName "Windows Remote Management (HTTP-In)" `
        -Direction Inbound `
        -Action Allow `
        -Protocol TCP `
        -LocalPort 5985 `
        -Profile Any | Out-Null
}

New-ItemProperty `
    -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
    -Name "LocalAccountTokenFilterPolicy" `
    -Value 1 `
    -PropertyType DWord `
    -Force | Out-Null

# Validate listeners and local connectivity before Packer polls from outside.
winrm enumerate winrm/config/listener | Out-Host
Test-NetConnection -ComputerName localhost -Port 5985 -WarningAction SilentlyContinue | Out-Null
Test-NetConnection -ComputerName localhost -Port $WinRMPort -WarningAction SilentlyContinue | Out-Null

Write-Host "WinRM HTTPS bootstrap complete."
Stop-Transcript | Out-Null