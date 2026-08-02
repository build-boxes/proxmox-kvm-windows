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

  os       = "win10"
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
    model    = "virtio"
    vlan_tag = var.network_vlan == "" ? null : var.network_vlan
  }

  disks {
    disk_size    = var.disk_size
    format       = var.disk_format
    storage_pool = var.storage_pool
    ssd          = var.disk_ssd_enabled
    discard      = true
    io_thread    = true
    type         = "scsi"
    cache_mode   = "none"
  }

  boot_iso {
    type              = "ide"
    iso_file          = "${var.storage_iso}:iso/${var.winserver2025_iso_name}"
    iso_checksum      = var.winserver2025_iso_checksum
    unmount           = true
    keep_cdrom_device = var.keep_cdrom_devices
  }

  additional_iso_files {
    type              = "ide"
    iso_file          = "${var.storage_iso}:iso/${var.virtio_iso_name}"
    iso_checksum      = var.virtio_iso_checksum
    unmount           = true
    keep_cdrom_device = var.keep_cdrom_devices
  }

  http_directory = "http"
  http_port_min  = 8100
  http_port_max  = 8100
  boot_wait      = "5s"

  communicator   = "winrm"
  winrm_username = "Administrator"
  winrm_password = var.administrator_password
  winrm_timeout  = var.winrm_timeout
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_use_ntlm = true
}
