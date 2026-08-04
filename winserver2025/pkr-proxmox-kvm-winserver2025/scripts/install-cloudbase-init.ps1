param(
    [string]$LogRoot = "C:\packer_build_logs"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -Path $LogRoot)) {
    New-Item -Path $LogRoot -ItemType Directory -Force | Out-Null
}

$logFile = Join-Path $LogRoot "install-cloudbase-init.log"
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $line = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-ddTHH:mm:ss"), $Level, $Message
    Write-Output $line
    Add-Content -Path $logFile -Value $line
}

if ($env:PACKER_ENABLE_CLOUDBASE_INIT -notmatch "^(?i:true|1|yes)$") {
    Write-Log "Skipping Cloudbase-Init installation because PACKER_ENABLE_CLOUDBASE_INIT is disabled."
    return
}

Write-Log "Downloading Cloudbase-Init installer from configured URL."
$msiPath = Join-Path $env:TEMP "CloudbaseInitSetup_Stable_x64.msi"
Invoke-WebRequest -Uri $env:PACKER_CLOUDBASE_INIT_URL -OutFile $msiPath
Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /qn /norestart" -Wait -NoNewWindow
Remove-Item -Path $msiPath -Force -ErrorAction SilentlyContinue
Write-Log "Cloudbase-Init MSI installed."

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
    Write-Log "Updated cloudbase-init.conf."

    $unattendConfig = Join-Path $configRoot "cloudbase-init-unattend.conf"
    if (Test-Path $unattendConfig) {
        Set-Content -Path $unattendConfig -Value $configText -Encoding ASCII
        Write-Log "Updated cloudbase-init-unattend.conf."
    }
}

if (Get-Service -Name "cloudbase-init" -ErrorAction SilentlyContinue) {
    Set-Service -Name "cloudbase-init" -StartupType Automatic
    Write-Log "Set cloudbase-init service startup type to Automatic."
}