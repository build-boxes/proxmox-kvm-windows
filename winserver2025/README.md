# WinServer2025 - Template - Notes
Proxmox VE can store Qemu KVM VM (Virtual Machine) images and LXC Container Images (CT templates) as template for quick deployment. LXC Containers (light weight VMs) share kernel with the Proxmox host, so only Linux is a possibility.

## WinServer2025 - Minimum Requirements
- Disk size - 32GB
- RAM - 4 GB
- TPM - true
- Cores - Minimum 2 cores - 1 GHz or faster.

## WinServer2025 - Sysprep
[Refernce 1 - https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/sysprep--generalize--a-windows-installation?view=windows-11](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/sysprep--generalize--a-windows-installation?view=windows-11)
[Reference 2 - https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/boot-windows-to-audit-mode-or-oobe?view=windows-11](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/boot-windows-to-audit-mode-or-oobe?view=windows-11)
```cmd
%WINDIR%\system32\sysprep\sysprep.exe /generalize /oobe /shutdown
```

## Refernce Links
1. [Poor Provider Docs: https://registry.terraform.io/providers/Telmate/proxmox/latest/docs](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
1. [Tutorial: https://spacelift.io/blog/terraform-proxmox-provider#4-configure-terraform-proxmox-provider](https://spacelift.io/blog/terraform-proxmox-provider#4-configure-terraform-proxmox-provider)
1. [Good Provider Docs: https://registry.terraform.io/providers/bpg/proxmox/latest/docs](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)

## Setup On Proxmox:
```
pveum role add TerraformProv -privs "Datastore.Allocate Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt SDN.Use"
pveum user add terraform-prov@pve --password <password>
pveum aclmod / -user terraform-prov@pve -role TerraformProv
sudo apt-get install -y xorriso p7zip-full
```

## Create SSH User for Good Promox Provider (bpg/proxmox)
```bash
useradd terraform-prov -m
passwd terraform-prov
groupadd special
usermod -a -G special,root terraform-prov
nano /etc/sudoers.d/pvecommands
cat /etc/sudoers.d/pvecommands
## Cmnd alias specification
Cmnd_Alias PVE_COMMANDS = /usr/sbin/qm
#
## Members of the special group may gain some privileges
%special ALL=(ALL) NOPASSWD: PVE_COMMANDS

root@pve:~#
```

## Automated Packer HCL Build

The folder [pkr-proxmox-kvm-winserver2025](./pkr-proxmox-kvm-winserver2025) now contains a first-pass Packer HCL implementation for building a Windows Server 2025 Proxmox template from ISO.

### What the Packer build automates
1. Proxmox VM creation with UEFI, TPM 2.0, VirtIO storage and networking, QEMU guest agent enabled, and a Cloud-Init drive prepared for later Terraform clones.
1. Windows unattended installation using an `Autounattend.xml` config CD.
1. WinRM HTTPS bootstrap so Packer can provision the guest over WinRM.
1. VirtIO guest tools installation and QEMU guest agent installation from the attached VirtIO ISO.
1. Optional OpenSSH Server installation, controlled by Packer variable `winserver2025_enable_openssh`.
1. RDP enablement and firewall rule activation.
1. Cloudbase-Init installation and baseline configuration for the later Terraform clone flow.
1. The documented sysprep preparation steps: optional `ipconfig /release`, the known Appx removal workaround, then `sysprep /generalize /oobe /shutdown`.
1. Automatic conversion of the powered-off VM into a Proxmox template unless the builder is configured otherwise.

### Files to edit before running Packer
1. Copy [vars/winserver2025.sample.pkrvars.hcl](./pkr-proxmox-kvm-winserver2025/vars/winserver2025.sample.pkrvars.hcl) to a local ignored file such as `winserver2025.auto.pkrvars.hcl` inside [pkr-proxmox-kvm-winserver2025](./pkr-proxmox-kvm-winserver2025).
1. Fill in at minimum:
   - `proxmox_host`
   - `proxmox_node`
   - `proxmox_api_user`
   - `proxmox_api_password`
   - `storage_iso`
   - `storage_pool`
   - `winserver2025_iso_name`
   - `virtio_iso_name`
   - `administrator_password`
1. Confirm the Windows Server 2025 ISO and VirtIO ISO are already present in the Proxmox ISO storage referenced by `storage_iso`.

### Run the build
```bash
cd pkr-proxmox-kvm-winserver2025
packer init .
packer fmt .
packer validate -var-file=winserver2025.auto.pkrvars.hcl .
packer build -var-file=winserver2025.auto.pkrvars.hcl .

## OR Simply
cd pkr-proxmox-kvm-winserver2025
./run_packer_build.sh \
     --proxmox-host 192.168.0.18 \
     --proxmox-os-user root \
     --moded-iso-name Win2025-SERVER_Moded_Unattended.iso \
     --orig-iso-name Win2025-SERVER_EVAL_x64FRE_en-us.iso \
     --win-image-name 'Windows Server 2025 SERVERDATACENTER' \
     --windows-time-zone America/Toronto \
     --proxmox-storage-iso ntfs2tb-iso \
     --administrator-password 'CHANGE_ME' \
     --winrm-port 5986
```

### Notes on the current implementation
1. The unattended build is designed to absorb the manual customization flow documented below, not replace the knowledge behind it.
1. The manual VirtIO MSI, QEMU guest agent install, OpenSSH option, RDP enablement, Cloudbase-Init install, pre-sysprep `ipconfig /release`, and Appx workaround are all represented in the Packer scripts.
1. The Proxmox builder unmounts the Windows and VirtIO ISOs after the build and converts the generalized VM into a template.
1. `*.auto.pkrvars.hcl` files are ignored by Git so local credentials and passwords stay out of the repository.

### WinRM troubleshooting during Packer build

If Packer pauses at `Waiting for WinRM to become available...`, use the checks below.

1. Verify basic network reachability from Linux:
   ```bash
   ping -c 3 <vm-ip>
   ```
1. Verify WinRM TCP reachability from Linux:
   ```bash
   nc -zv -w 3 <vm-ip> 5986
   nc -zv -w 3 <vm-ip> 5985
   ```
1. Verify WinRM HTTPS endpoint from Linux:
   ```bash
   curl -k -I https://<vm-ip>:5986/wsman
   ```
   - `HTTP 405` with `allow: POST` is expected for `HEAD` and confirms the endpoint is alive.
   - `HTTP 401` is also acceptable and means authentication is required.
1. Verify listener state inside the Windows VM (Administrator PowerShell):
   ```powershell
   winrm enumerate winrm/config/listener
   Test-NetConnection -ComputerName localhost -Port 5986
   ```
1. If HTTPS 5986 is not available, ensure these are true:
   - WinRM service is running and set to automatic.
   - A WinRM HTTPS listener exists.
   - Windows firewall allows inbound TCP 5986.

Build flow notes:
1. In this repo, unattended first-logon runs WinRM bootstrap before longer install tasks so communicator startup is not delayed.
1. The WinRM bootstrap script logs to `C:\packer_build_logs\bootstrap-winrm.log` inside the guest for post-failure diagnosis.

## Windows Server 2025 - Template Creation

1. Manually download the Windows Server 2025 DataCenter Edition (Evaluation) ISO, and save it on your proxmox server with the name in variable `${winserver2025_iso_name}="Win2025-SERVER_EVAL_x64FRE_en-us.iso"` in the proxmox ISO storage named in variable `${storage_iso}`.
1. Install Windows Server 2025 from the downloaded ISO image.
1. Login as Administrator and Install `virtio-win-gt-x64`
   - This will install all Qemu drivers for Windows.
   - Download the binary MSI installer from [virtio-win-gt-x64.msi](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.271-1/virtio-win-gt-x64.msi)
1. Instal Qemu-Agent
   1. Download the ISO from [virtio-win-0.1.271.iso](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.271-1/virtio-win-0.1.271.iso)
   1. Mount the ISO temporarily as local Disk.
   1. Go to the mounted ISO in explorer.
   1. The guest agent installer is in the `guest-agent` directory.
   1. Execute the installer with double click, either `qemu-ga-x86_64.msi` (64-bit) or `qemu-ga-i386.msi` (32-bit).
   After that the qemu-guest-agent should be up and running. You can validate this in the list of Window Services, or in a PowerShell with:
   ```
   PS C:\Users\Administrator> Get-Service QEMU-GA

   Status   Name               DisplayName
   ------   ----               -----------
   Running  QEMU-GA            QEMU Guest Agent
   ```
   If it is not running, you can use the Services control panel to start it and make sure that it will start automatically on the next boot.
1. Install OpenSSH Server. This is optional in the automated build and controlled by the Packer variable `${winserver2025_enable_openssh}`.
   ```
   PS C:\Users\Administrator> Add-WindowsCapability -Online -Name OpenSSH
   PS C:\Users\Administrator> Add-WindowsCapability -Online -Name OpenSSH.Server
   PS C:\Users\Administrator> Set-Service -Name sshd -StartupType Automatic
   PS C:\Users\Administrator> Set-Service -Name ssh-agent -StartupType Automatic
   PS C:\Users\Administrator> netsh advfirewall firewall add rule name="SSH Port" dir=in action=allow protocol=TCP localport=22 remoteip=any
   PS C:\Users\Administrator> Start-Service sshd
   PS C:\Users\Administrator> get-service sshd
   ```
1. Enable Remote RDP Sessions
   ```
   PS C:\Users\Administrator> Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -Value 0
   PS C:\Users\Administrator> Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
   ```
1. Download Cloudbase-init Installer. Do not launch it yet.
   - Download Link: [https://cloudbase.it/cloudbase-init/#download](https://cloudbase.it/cloudbase-init/#download)
   - Actual Download Link [CloudbaseInitSetup_Stable_x64.msi](https://cloudbase.it/downloads/CloudbaseInitSetup_Stable_x64.msi)
1. Shutdown the VM. Remove all CD Roms and unneeded binary downloads while stopped.
1. Start the VM and Login again as Administrator. Temporarily release Network.
   ```
   PS C:\Users\Administrator> ipconfig /release
   ```
1. Install Cloudbase-init as a Service, in the end select Sysprep and Shutdown option.
   - If Errors due to Packages, then remove that package and retry.
   ```
   PS C:\Users\Administrator> Remove-AppxPackage -Package Microsoft.WidgetsPlatformRuntime_1.6.1.0_x64__8wekyb3d8bbwe -allusers
   ```
1. After successful shutdown, convert the QEMU VM to Template.

## Using Terraform to Clone Qemu VM template on Proxmox
```
terraform init
terraform plan
terraform apply -auto-approve
terrform destroy -auto-approve
```

## Terraform Apply - Errors
- Proxmox Snippets folder permission
  - Folder permissions are automatically reset after few hours
  - Permanent Fix - To Do
  - Temporary Fix:
  - SSH to Promox Host
    ```
    root@pve:~# ls -lart /var/lib/vz/snippets/
    total 16
    drwxr-xr-x 6 root           root           4096 Jun 12 16:30 ..
    drwxr-xr-x 2 root           root           4096 Jun 12 16:31 .
    root@pve:~# chmod -R 775 /var/lib/vz/snippets/
    root@pve:~# ls -lart /var/lib/vz/snippets/
    total 16
    drwxr-xr-x 6 root           root           4096 Jun 12 16:30 ..
    drwxrwxr-x 2 root           root           4096 Jun 12 16:31 .
    ```

## Using Standalone Ansible
Connect to the Windows Server 2025, using server-local User Accounts with their local passwords as follows.

1. Using winrm-Ntlm-transport Prompt for Passowrd:
   ```
   ansible all -i '192.168.0.105,' -m win_ping -u 'Administrator' -e 'ansible_connection=winrm' -e 'ansible_winrm_transport=ntlm' -e 'ansible_port=5986' -e 'ansible_winrm_server_cert_validation=ignore' --ask-pass
   #-- results in:
   SSH password: <<YOUR INPUT>>
   #-- results in:
   192.168.0.105 | SUCCESS => {
       "changed": false,
       "ping": "pong"
   }
   ```
1. Using winrm-Ntlm-transport included Password:
   ```
   ansible all -i '192.168.0.105,' -m win_ping -u 'Administrator' -e 'ansible_password=PASSWORD' -e 'ansible_connection=winrm' -e 'ansible_winrm_transport=ntlm' -e 'ansible_port=5986' -e 'ansible_winrm_server_cert_validation=ignore'
   #-- results in:
   192.168.0.105 | SUCCESS => {
       "changed": false,
       "ping": "pong"
   }
   ```
1. Using winrm-Kerberos-transport (On Domain Joined Servers, after getting a kerberos ticket):
   ```
   ansible all -i '192.168.0.105,' -m win_ping -u 'hammad.rauf@hexword.ca' -e 'ansible_connection=winrm' -e 'ansible_winrm_transport=kerberos' -e 'ansible_port=5986' -e 'ansible_winrm_server_cert_validation=ignore'
   #-- results in:
   192.168.0.105 | SUCCESS => {
       "changed": false,
       "ping": "pong"
   }
   ```

For the above first 2 examples to work the Windows Server Default policy settings need to be modified, as shown below. The winrm-kerberos-transport method on domain joined Win 2025 server with a user having been given access to that server, will not need the following.

<b>NOTE:</b> This Terraform script does this policy change on Initial Boot if the tfvar variable <i>enable_winrm_local_account_remote_login_policy</i>, as a default arrangment, so it does not need to be manually executed. Included here for documentation and future reference use only.
```
# Run the following on the target Windows Server 2025, in an Administrative PowerShell Prompt:
C:\> New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "LocalAccountTokenFilterPolicy" -Value 1 -PropertyType DWord -Force
```