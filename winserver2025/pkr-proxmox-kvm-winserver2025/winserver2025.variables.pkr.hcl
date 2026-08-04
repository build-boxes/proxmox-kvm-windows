variable "storage_iso" {
  type        = string
  description = "Proxmox storage that holds installer ISOs"
  default     = "local"
}

variable "storage_pool" {
  type        = string
  description = "Proxmox storage that holds the VM disks and EFI/TPM state"
  default     = "local-lvm"
}

variable "winserver2025_iso_name" {
  type        = string
  description = "Windows Server 2025 ISO filename already present in Proxmox ISO storage"
  default     = "Win2025-SERVER_EVAL_x64FRE_en-us.iso"
}

variable "winserver2025_iso_checksum" {
  type        = string
  description = "Checksum for the Windows Server 2025 ISO, or 'none' if verification is skipped"
  default     = "none"
}

variable "winserver2025_modified_iso_name" {
  type    = string
  description = "Name of the packer created Modified ISO Installer for Win2025, consisting of all contents of Original Win2025 ISO PLUS autounattended.xml file."
  default = "Win2025-SERVER_Moded_Unattended.iso"
}


variable "winserver2025_image_name" {
  type        = string
  description = "Image name from the Windows installer WIM to deploy"
  default     = "Windows Server 2025 SERVERDATACENTER"
}

variable "virtio_iso_name" {
  type        = string
  description = "VirtIO ISO filename already present in Proxmox ISO storage"
  default     = "virtio-win-0.1.271.iso"
}

variable "virtio_iso_checksum" {
  type        = string
  description = "Checksum for the VirtIO ISO, or 'none' if verification is skipped"
  default     = "none"
}

variable "virtio_guest_tools_url" {
  type        = string
  description = "Optional VirtIO guest tools MSI download URL"
  default     = "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.271-1/virtio-win-gt-x64.msi"
}

variable "virtio_guest_tools_checksum" {
  type        = string
  description = "Checksum for the VirtIO guest tools MSI, or 'none' if verification is skipped"
  default     = "none"
}

variable "cloudbase_init_url" {
  type        = string
  description = "Cloudbase-Init MSI download URL"
  default     = "https://cloudbase.it/downloads/CloudbaseInitSetup_Stable_x64.msi"
}

variable "cloudbase_init_checksum" {
  type        = string
  description = "Checksum for the Cloudbase-Init MSI, or 'none' if verification is skipped"
  default     = "none"
}

variable "vm_name" {
  type        = string
  description = "Temporary VM name used during the Packer build"
  default     = "pckr-winserver2025"
}

variable "template_name" {
  type        = string
  description = "Final Proxmox template name"
  default     = "tpl-winserver2025"
}

variable "vmid" {
  type        = number
  description = "Proxmox Template ID"
  default     = 9999
}

variable "cpu_type" {
  type        = string
  description = "Proxmox CPU model"
  default     = "host"
}

variable "cores" {
  type        = number
  description = "VM CPU cores"
  default     = 2
}

variable "sockets" {
  type        = number
  description = "VM CPU sockets"
  default     = 1
}

variable "memory_mb" {
  type        = number
  description = "VM memory in megabytes"
  default     = 4096
}

variable "disk_format" {
  type        = string
  description = "Proxmox disk backing format"
  default     = "qcow2"
}

variable "disk_bus" {
  type        = string
  description = "Disk bus type for the primary OS disk (e.g. scsi or sata)"
  default     = "scsi"
  validation {
    condition     = contains(["scsi", "sata", "virtio"], var.disk_bus)
    error_message = "Disk bus must be one of: scsi, sata, or virtio."
  }
}

variable "disk_size" {
  type        = string
  description = "Boot disk size"
  default     = "64G"
}

variable "disk_ssd_enabled" {
  type        = bool
  description = "Enable SSD emulation for the boot disk"
  default     = true
}

variable "network_bridge" {
  type        = string
  description = "Proxmox bridge to connect the VM to"
  default     = "vmbr0"
}

variable "network_model" {
  type        = string
  description = "Virtual NIC model for the guest OS"
  default     = "e1000"
  validation {
    condition     = contains(["e1000", "virtio"], var.network_model)
    error_message = "Network model must be either e1000 or virtio."
  }
}

variable "network_vlan" {
  type        = string
  description = "Optional VLAN tag"
  default     = ""
}

variable "network_firewall" {
  type        = bool
  description = "Enable the Proxmox firewall for the VM NIC"
  default     = true
}

variable "proxmox_api_password" {
  type        = string
  description = "Proxmox API password"
  sensitive   = true
  default     = ""
}

variable "proxmox_api_user" {
  type        = string
  description = "Proxmox API username"
  default     = "root@pam"
}

variable "proxmox_host" {
  type        = string
  description = "Proxmox host or cluster endpoint without protocol"
  default     = ""
}

variable "proxmox_ve_endpoint" {
  type    = string
  default = null
}

variable "proxmox_node" {
  type        = string
  description = "Proxmox node name"
  default     = ""
}

variable "proxmox_insecure_skip_tls_verify" {
  type        = bool
  description = "Skip TLS verification for the Proxmox API"
  default     = true
}

variable "administrator_password" {
  type        = string
  description = "Initial Administrator password used by unattended install and WinRM communicator"
  sensitive   = true
  default     = "HeyH0Password"
}

variable "windows_time_zone" {
  type        = string
  description = "Windows timezone identifier"
  default     = "UTC"
}

variable "windows_setup_log_root" {
  type        = string
  description = "Directory where Autounattend-triggered PowerShell scripts write logs"
  default     = "C:\\packer_build_logs"
}

variable "winrm_timeout" {
  type        = string
  description = "How long Packer should wait for WinRM to become available"
  default     = "6h"
}

variable "winrm_port" {
  type        = number
  description = "WinRM HTTPS port"
  default     = 5986
}

variable "keep_cdrom_devices" {
  type        = bool
  description = "Keep empty CD-ROM devices attached after the build"
  default     = false
}

variable "winserver2025_enable_openssh" {
  type        = bool
  description = "Install and enable the Windows OpenSSH Server feature"
  default     = false
}

variable "winserver2025_enable_rdp" {
  type        = bool
  description = "Enable Remote Desktop and its firewall rules"
  default     = true
}

variable "winserver2025_enable_cloudbase_init" {
  type        = bool
  description = "Install Cloudbase-Init in the template"
  default     = true
}

variable "winserver2025_enable_virtio_guest_tools" {
  type        = bool
  description = "Install the VirtIO guest tools MSI in addition to driver injection"
  default     = true
}

variable "winserver2025_enable_ipconfig_release_before_sysprep" {
  type        = bool
  description = "Run ipconfig /release just before sysprep"
  default     = true
}

variable "winserver2025_enable_sysprep_appx_workaround" {
  type        = bool
  description = "Apply the documented Appx removal workaround before sysprep"
  default     = true
}

variable "vm_image_tags" {
  type        = list(string)
  description = "Tags to apply to the final Proxmox template"
  default     = ["template", "windows", "winserver", "2025"]
}

variable "boot_command_wait_seconds" {
  type        = string
  description = "Seconds to wait for the boot command to complete, Example: '5s'"
  default     = "5s"
}