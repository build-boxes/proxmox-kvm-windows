# Adapted from: https://github.com/build-boxes/terraform-proxmox-windows-example/blob/main/main.tf
#
#
# see https://github.com/hashicorp/terraform
terraform {
  required_providers {
    # see https://registry.terraform.io/providers/hashicorp/random
    random = {
      source  = "hashicorp/random"
      version = "3.7.1"
    }
    # see https://registry.terraform.io/providers/hashicorp/cloudinit
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.6"
    }
    # see https://registry.terraform.io/providers/bpg/proxmox
    # see https://github.com/bpg/terraform-provider-proxmox
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.93.0"
    }
    time = {
          source = "hashicorp/time"
          version = "0.13.1"
    }
  }
}

provider "proxmox" {
    endpoint = var.PROXMOX_VE_ENDPOINT
    username = var.PROXMOX_VE_USERNAME
    password = var.PROXMOX_VE_PASSWORD
    insecure = var.PROXMOX_VE_INSECURE
  ssh {
    agent = true
    node {  
      name    = var.proxmox_node_name
      address = var.proxmox_node_address
    }
  }
}


# see https://registry.terraform.io/providers/bpg/proxmox/0.75.0/docs/data-sources/virtual_environment_vms
data "proxmox_virtual_environment_vms" "windows_templates" {
  tags = var.proxmox_vm_template_tags
  node_name = var.proxmox_node_name
}

# see https://registry.terraform.io/providers/bpg/proxmox/0.75.0/docs/data-sources/virtual_environment_vm
data "proxmox_virtual_environment_vm" "windows_template" {
  #node_name = data.proxmox_virtual_environment_vms.windows_templates.vms[0].node_name
  #vm_id     = data.proxmox_virtual_environment_vms.windows_templates.vms[0].vm_id
  node_name = local.template_vm.node_name
  vm_id     = local.template_vm.vm_id  
}

# the virtual machine cloudbase-init cloud-config.
# NB the parts are executed by their declared order.
# see https://github.com/cloudbase/cloudbase-init
# see https://cloudbase-init.readthedocs.io/en/1.1.6/userdata.html#cloud-config
# see https://cloudbase-init.readthedocs.io/en/1.1.6/userdata.html#userdata
# see https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config.html
# see https://developer.hashicorp.com/terraform/language/expressions#string-literals
data "cloudinit_config" "example" {
  gzip          = false
  base64_encode = false
  part {
    filename     = "initialize-disks.ps1"
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #ps1_sysnative
      # initialize all (non-initialized) disks with a single NTFS partition.
      # NB we have this script because disk initialization is not yet supported by cloudbase-init.
      # NB the output of this script appears on the cloudbase-init.log file when the
      #    debug mode is enabled, otherwise, you will only have the exit code.
      Get-Disk `
        | Where-Object {$_.PartitionStyle -eq 'RAW'} `
        | ForEach-Object {
          Write-Output "Initializing disk #$($_.Number) ($($_.Size) bytes)..."
          $volume = $_ `
            | Initialize-Disk -PartitionStyle MBR -PassThru `
            | New-Partition -AssignDriveLetter -UseMaximumSize `
            | Format-Volume -FileSystem NTFS -NewFileSystemLabel "disk$($_.Number)" -Confirm:$false
          Write-Output "Initialized disk #$($_.Number) ($($_.Size) bytes) as $($volume.DriveLetter):."
        }
      EOF
  }
  part {
    filename     = "AdministratorPWD.ps1"
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #ps1_sysnative
      # this is a PowerShell script.
      # NB this script will be executed as the cloudbase-init user (which is in the Administrators group).
      # NB this script will be executed by the cloudbase-init service once, but to be safe, make sure its idempotent.
      # NB the output of this script appears on the cloudbase-init.log file when the
      #    debug mode is enabled, otherwise, you will only have the exit code.
      Start-Transcript -Append "C:\cloudinit-config-example.ps1.log"
      # Define the new password
      $SecurePassword = ConvertTo-SecureString "${var.administrator_new_password}" -AsPlainText -Force
      
      # Get the administrator account
      $AdminAccount = Get-LocalUser -Name "Administrator"
      
      # Set the new password for the administrator account
      Set-LocalUser -Name "Administrator" -Password $SecurePassword
      
      # Confirm the password was updated
      Write-Output "Administrator password has been updated successfully."
      EOF
  }  
  part {
    content_type = "text/cloud-config"
    content      = <<-EOF
      #cloud-config
      hostname: ${var.prefix}
      timezone: America/Toronto
      users:
        - name: ${jsonencode(var.superuser_username)}
          passwd: ${jsonencode(var.superuser_new_password)}
          primary_group: Administrators
          # ssh_authorized_keys:
          #   - ${jsonencode(trimspace(file("${var.pub_key_file}")))}
      # these runcmd commands are concatenated together in a single batch script and then executed by cmd.exe.
      # NB this script will be executed as the cloudbase-init user (which is in the Administrators group).
      # NB this script will be executed by the cloudbase-init service once, but to be safe, make sure its idempotent.
      # NB the output of this script appears on the cloudbase-init.log file when the
      #    debug mode is enabled, otherwise, you will only have the exit code.
      runcmd:
        - "echo # Script path"
        - "echo %~f0"
        - "echo # Sessions"
        - "query session"
        - "echo # whoami"
        - "whoami /all"
        - "echo # Windows version"
        - "ver"
        - "echo # Environment variables"
        - "set"
      EOF
  }
  part {
    filename     = "CheckAndEnablewinRM.ps1"
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #ps1_sysnative
      # this is a PowerShell script.
      # NB this script will be executed as the cloudbase-init user (which is in the Administrators group).
      # NB this script will be executed by the cloudbase-init service once, but to be safe, make sure its idempotent.
      # NB the output of this script appears on the cloudbase-init.log file when the
      #    debug mode is enabled, otherwise, you will only have the exit code.
      # Set up Administrators SSH Authorized Keys
      Add-Content -Force -Path "C:\ProgramData\ssh\administrators_authorized_keys" -Value ${jsonencode(trimspace(file("${var.pub_key_file}")))};icacls.exe "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
      Start-Transcript -Append "C:\cloudinit-config-example.ps1.log"
      function Write-Title($title) {
        Write-Output "`n#`n# $title`n#"
      }
      Write-Title "Script path"
      Write-Output $PSCommandPath
      Write-Title "Sessions"
      query session | Out-String
      Write-Title "whoami"
      whoami /all | Out-String
      Write-Title "Windows version"
      cmd /c ver | Out-String
      Write-Title "Environment Variables"
      dir env:
      Write-Title "TimeZone"
      Get-TimeZone
      ## Check if WinRM is enabled
      # 1. Ensure WinRM service is installed, active, and starts automatically
      $service = Get-Service -Name WinRM -ErrorAction SilentlyContinue

      if (-not $service) {
          Write-Output "WinRM is not installed. Installing..." -ForegroundColor Yellow
          Enable-PSRemoting -Force
      } else {
          Write-Output "WinRM is installed. Enforcing active status..." -ForegroundColor Cyan
      }

      Set-Service -Name WinRM -StartupType Automatic
      Start-Service -Name WinRM -ErrorAction SilentlyContinue

      # 2. Check if an HTTPS listener already exists
      $httpsListener = Get-ChildItem -Path WSMan:\LocalHost\Listener | Where-Object { $_.Keys -contains "Transport=HTTPS" }

      if (-not $httpsListener) {
          Write-Output "No HTTPS listener found. Generating self-signed SSL certificate..." -ForegroundColor Yellow
          
          # Generate certificate utilizing the computer's local hostname
          $hostname = $env:COMPUTERNAME
          $cert = New-SelfSignedCertificate -DnsName $hostname -CertStoreLocation "Cert:\LocalMachine\My" -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.1")
          
          Write-Output "Certificate created with Thumbprint: $($cert.Thumbprint)" -ForegroundColor Green

          # Create the WSMan HTTPS listener mapping it to the new certificate
          Write-Output "Creating WinRM HTTPS listener on Port 5986..." -ForegroundColor Yellow
          New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $cert.Thumbprint -Force | Out-Null
      } else {
          Write-Output "WinRM HTTPS listener already exists." -ForegroundColor Green
      }

      # 3. Open Windows Firewall for TCP port 5986
      Write-Output "Configuring Windows Firewall rule for WinRM HTTPS..." -ForegroundColor Yellow
      $firewallRule = Get-NetFirewallRule -Name "WinRM-HTTPS-Inbound" -ErrorAction SilentlyContinue

      if (-not $firewallRule) {
          New-NetFirewallRule -Name "WinRM-HTTPS-Inbound" `
                              -DisplayName "Windows Remote Management (HTTPS-In)" `
                              -Description "Inbound rule for WinRM traffic over SSL/HTTPS." `
                              -Direction Inbound `
                              -LocalPort 5986 `
                              -Protocol TCP `
                              -Action Allow `
                              -Profile Any | Out-Null
          Write-Output "Firewall rule created successfully." -ForegroundColor Green
      } else {
          Write-Output "Firewall rule already exists." -ForegroundColor Green
      }

      Write-Output "WinRM HTTPS Configuration Complete!" -ForegroundColor Green
      EOF
  }
}

# see https://registry.terraform.io/providers/bpg/proxmox/0.75.0/docs/resources/virtual_environment_file
resource "proxmox_virtual_environment_file" "example_ci_user_data" {
  content_type = "snippets"
  datastore_id = var.proxmox_datastore_id
  node_name    = var.proxmox_node_name
  source_raw {
    file_name = "${var.prefix}-ci-user-data.txt"
    data      = data.cloudinit_config.example.rendered
  }
}

# see https://registry.terraform.io/providers/bpg/proxmox/0.75.0/docs/resources/virtual_environment_vm
resource "proxmox_virtual_environment_vm" "clone_edited_template" {
  name      = var.prefix
  node_name = var.proxmox_node_name
  tags      = var.proxmox_vm_tags
  clone {
    vm_id = data.proxmox_virtual_environment_vm.windows_template.vm_id
    full  = true
  }
  cpu {
    #type  = "host"
    #type  = "x86-64-v2-AES"
    type = var.cpu_type_host ? "host" : "x86-64-v2-AES"
    cores = 2
  }
  memory {
    dedicated = endswith(var.memory_size, "G") ? 1024 * tonumber(replace(var.memory_size, "G", "")) : ( endswith(var.memory_size, "M") ? tonumber(replace(var.memory_size, "M", "")) : tonumber(var.memory_size) )
  }
  network_device {
    bridge = "vmbr0"
    mac_address = var.vm_mac_address
  }
  disk {      # Boot Disk, Size can be increased here. Then manually Increase Volume size inside Windows-2025.
    datastore_id = var.proxmox_datastore_id
    #interface   = "scsi0"
    interface   = "sata0"
    #file_format = "raw"
    file_format = "qcow2"
    iothread    = true
    ssd         = var.disk_boot_ssd_enabled
    discard     = "on"
    size        = endswith(var.disk_size_boot, "G") ? tonumber(replace(var.disk_size_boot, "G", "")) : ( endswith(var.disk_size_boot, "M") ? tonumber(replace(var.disk_size_boot, "M", "")) / 1024 : tonumber(var.disk_size_boot) / 1024 )
  }
  ## Add additional Disks here, if required.
  ##
  ##
  agent {
    enabled = true
    trim    = true
  }
  # NB we use a custom user data because this terraform provider initialization
  #    block is not entirely compatible with cloudbase-init (the cloud-init
  #    implementation that is used in the windows base image).
  # see https://pve.proxmox.com/wiki/Cloud-Init_Support
  # see https://cloudbase-init.readthedocs.io/en/latest/services.html#openstack-configuration-drive
  # see https://registry.terraform.io/providers/bpg/proxmox/0.75.0/docs/resources/virtual_environment_vm#initialization
  initialization {
    user_data_file_id = proxmox_virtual_environment_file.example_ci_user_data.id
    datastore_id      = var.proxmox_datastore_id
    # # >>> Fixed IP -- Start
    # # Use following if need fixed IP Address, otherwise comment out
    ip_config {
      ipv4 {
        address = var.vm_fixed_ip
        gateway = var.vm_fixed_gateway
      }
    }
    dns {
      servers = var.vm_fixed_dns
    }
    # # >>> Fixed IP -- End
  }
}

resource "time_sleep" "wait_7_minutes" {
  depends_on = [proxmox_virtual_environment_vm.clone_edited_template]
  # 12 minutes sleep. I have a slow Proxmox Host :(
  create_duration = "7m"
}

# # NB this can only connect after about 3m15s (because the ssh service in the
# #    windows base image is configured as "delayed start").
resource "null_resource" "ssh_into_vm" {
  depends_on = [time_sleep.wait_7_minutes]
  provisioner "remote-exec" {
    connection {
      target_platform = "windows"
      type            = "ssh"
      host            = coalesce(try(split("/",proxmox_virtual_environment_vm.clone_edited_template.initialization[0].ip_config[0].ipv4[0].address)[0], null),proxmox_virtual_environment_vm.clone_edited_template.ipv4_addresses[index(proxmox_virtual_environment_vm.clone_edited_template.network_interface_names, "Ethernet")][0] )
      user            = var.superuser_username
      password        = var.superuser_new_password
      private_key = file("${var.pvt_key_file}")
      agent = false
      timeout = "5m"
    }
    # NB this is executed as a batch script by cmd.exe.
    inline = [
      <<-EOF
      whoami.exe /all
      EOF
    ]
  }
}

