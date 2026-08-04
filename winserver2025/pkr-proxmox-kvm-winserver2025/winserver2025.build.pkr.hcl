locals {
  powershell_env = [
    "PACKER_ENABLE_VIRTIO_GUEST_TOOLS=${var.winserver2025_enable_virtio_guest_tools}",
    "PACKER_VIRTIO_GUEST_TOOLS_URL=${var.virtio_guest_tools_url}",
    "PACKER_VIRTIO_GUEST_TOOLS_CHECKSUM=${var.virtio_guest_tools_checksum}",
    "PACKER_ENABLE_OPENSSH=${var.winserver2025_enable_openssh}",
    "PACKER_ENABLE_RDP=${var.winserver2025_enable_rdp}",
    "PACKER_ENABLE_CLOUDBASE_INIT=${var.winserver2025_enable_cloudbase_init}",
    "PACKER_CLOUDBASE_INIT_URL=${var.cloudbase_init_url}",
    "PACKER_CLOUDBASE_INIT_CHECKSUM=${var.cloudbase_init_checksum}",
    "PACKER_ENABLE_IPCONFIG_RELEASE_BEFORE_SYSPREP=${var.winserver2025_enable_ipconfig_release_before_sysprep}",
    "PACKER_ENABLE_SYSPREP_APPX_WORKAROUND=${var.winserver2025_enable_sysprep_appx_workaround}"
  ]
  original_iso = "${var.storage_iso}:iso/${var.winserver2025_iso_name}"
  modified_iso = "${var.storage_iso}:iso/${var.winserver2025_modified_iso_name}"
}


build {
  sources = ["source.proxmox-iso.winserver2025"]

  # provisioner "powershell" {
  #   environment_vars = local.powershell_env
  #   script           = "scripts/install-virtio-guest-tools.ps1"
  # }

  provisioner "powershell" {
    environment_vars = local.powershell_env
    script           = "scripts/install-openssh.ps1"
    timeout          = "85m"
    retry_count     = 17
    retry_sleep     = "5m"
  }

  provisioner "powershell" {
    environment_vars = local.powershell_env
    script           = "scripts/enable-rdp.ps1"
    timeout          = "10m"
    retry_count     = 10
    retry_sleep     = "1m"
  }

  provisioner "windows-restart" {
    restart_timeout = "15m"
  }

  provisioner "powershell" {
    environment_vars = local.powershell_env
    script           = "scripts/install-cloudbase-init.ps1"
    timeout          = "10m"
    retry_count     = 10
    retry_sleep     = "1m"
  }

  provisioner "powershell" {
    environment_vars = local.powershell_env
    script           = "scripts/finalize-template.ps1"
    timeout          = "10m"
    retry_count     = 10
    retry_sleep     = "1m"
  }


}
