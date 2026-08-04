$ErrorActionPreference = "Stop"

if ($env:PACKER_ENABLE_CLOUDBASE_INIT -notmatch "^(?i:true|1|yes)$") {
    Write-Host "Skipping Cloudbase-Init installation."
    exit 0
}

$msiPath = Join-Path $env:TEMP "CloudbaseInitSetup_Stable_x64.msi"
Invoke-WebRequest -Uri $env:PACKER_CLOUDBASE_INIT_URL -OutFile $msiPath
Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /qn /norestart" -Wait -NoNewWindow
Remove-Item -Path $msiPath -Force -ErrorAction SilentlyContinue

$configRoot = "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf"
if (Test-Path $configRoot) {
    $configText = @"
username=Administrator
groups=Administrators
inject_user_password=true
first_logon_behaviour=no
allow_reboot=false
stop_service_on_exit=false
metadata_services=cloudbaseinit.metadata.services.configdrive.ConfigDriveService
verbose=true
debug=true
"@

    Set-Content -Path (Join-Path $configRoot "cloudbase-init.conf") -Value $configText -Encoding ASCII

    $unattendConfig = Join-Path $configRoot "cloudbase-init-unattend.conf"
    if (Test-Path $unattendConfig) {
        Set-Content -Path $unattendConfig -Value $configText -Encoding ASCII
    }
}

if (Get-Service -Name "cloudbase-init" -ErrorAction SilentlyContinue) {
    Set-Service -Name "cloudbase-init" -StartupType Automatic
}