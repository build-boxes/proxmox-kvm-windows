source "proxmox-iso" "winserver2025" {
  proxmox_url              = "https://${var.proxmox_host}/api2/json"
  username                 = var.proxmox_api_user
  password                 = var.proxmox_api_password
  insecure_skip_tls_verify = var.proxmox_insecure_skip_tls_verify
  node                     = var.proxmox_node
  task_timeout             = "30m"

  vm_name              = var.vm_name
  template_name        = var.template_name
  template_description = "Windows Server 2025 Proxmox template built by Packer -- Created: ${formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())}"
  tags                 = join(";", var.vm_image_tags)
  vm_id                = var.vmid

  os       = "win11"
  cpu_type = var.cpu_type
  sockets  = var.sockets
  cores    = var.cores
  memory   = var.memory_mb
  machine  = "q35"
  bios     = "ovmf"

  efi_config {
    efi_storage_pool  = var.storage_pool
    pre_enrolled_keys = true
    efi_format        = "raw"
    efi_type          = "4m"
  }

  tpm_config {
    tpm_storage_pool = var.storage_pool
    tpm_version      = "v2.0"
  }

  rng0 {
    source    = "/dev/urandom"
    max_bytes = 1024
    period    = 1000
  }

  scsi_controller         = "virtio-scsi-single"
  qemu_agent              = true
  cloud_init              = true
  cloud_init_storage_pool = var.storage_pool
  cloud_init_disk_type    = "ide"

  network_adapters {
    bridge   = var.network_bridge
    firewall = var.network_firewall
    model    = var.network_model
    vlan_tag = var.network_vlan == "" ? null : var.network_vlan
  }

  disks {
    disk_size    = var.disk_size
    format       = var.disk_format
    storage_pool = var.storage_pool
    ssd          = var.disk_ssd_enabled
    discard      = true
    io_thread    = contains(["scsi", "virtio"], var.disk_bus)
    type         = var.disk_bus
    cache_mode   = "none"
  }

  boot_iso {
    type              = "ide"
    iso_file          = "${var.storage_iso}:iso/${var.winserver2025_modified_iso_name}"
    iso_checksum      = var.winserver2025_iso_checksum
    unmount           = true
    keep_cdrom_device = var.keep_cdrom_devices
  }

  additional_iso_files {
    cd_content = {
      "autounattend.xml" = templatefile("./http/Autounattend.xml.pkrtpl", {image_name = var.winserver2025_image_name, time_zone = var.windows_time_zone , administrator_password = var.administrator_password, winrm_port = var.winrm_port }),
      "bootstrap-winrm.ps1" = file("./scripts/bootstrap-winrm.ps1"),
      "enable-rdp.ps1" = file("./scripts/enable-rdp.ps1"),
      "finalize-template.ps1" = file("./scripts/finalize-template.ps1"),
      "install-cloudbase-init.ps1" = file("./scripts/install-cloudbase-init.ps1"),
      "install-openssh.ps1" = file("./scripts/install-openssh.ps1"),
      "install-virtio-guest-tools.ps1" = file("./scripts/install-virtio-guest-tools.ps1")
    }
    cd_label = "PACKERDEV"
    iso_storage_pool = "${var.storage_iso}"
    unmount = true
    type = "ide"
    index = 2
  }
  additional_iso_files {
    type              = "ide"
    iso_file          = "${var.storage_iso}:iso/${var.virtio_iso_name}"
    iso_checksum      = var.virtio_iso_checksum
    unmount           = true
    index = 3
    keep_cdrom_device = var.keep_cdrom_devices
  }

  boot_wait    = "5s"
  boot_command = [
    "<enter>"
  ]

  # WinRM
  communicator          = "winrm"
  winrm_username        = "Administrator"
  winrm_password        = var.administrator_password
  winrm_timeout         = var.winrm_timeout
  winrm_port            = var.winrm_port
  winrm_use_ssl         = true
  winrm_insecure        = true
  winrm_use_ntlm        = true  
}
