variable "proxmox_node_name" {
  type    = string
  default = "pve"
}

variable "proxmox_node_address" {
  type = string
}

variable "PROXMOX_VE_ENDPOINT" {
    type = string
    default = "https://192.168.4.20:8006/api2/json"
}

variable "PROXMOX_VE_USERNAME" {
    type = string
    sensitive = true
    default = "admin@pve"
}

variable "PROXMOX_VE_PASSWORD" {
    type = string
    sensitive = true
    default = "PassW0rd123!!"
}

variable "PROXMOX_VE_INSECURE" {
    type = bool
    default = false
}


variable "prefix" {
  # This is used to rename the host to this name.description
  # also used as a prefix for text and log files names.
  type    = string
  default = "eagle01"
}

variable "pub_key_file" {
  type = string
  default = "~/.ssh/id_rsa.pub"
}

variable "pvt_key_file" {
  type = string
  default = "~/.ssh/id_rsa"
  sensitive = true
}

variable "superuser_username" {
  type    = string
  default = "terraform"
}

variable "superuser_old_password" {
  type      = string
  # NB the password will be reset by the cloudbase-init SetUserPasswordPlugin plugin.
  # NB this value must meet the Windows password policy requirements.
  #    see https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/password-must-meet-complexity-requirements
  # Password with @ symbol has issues in cloudbase-init scripts escape-sequencing in terraform ".tf" files
  default = "HeyH0Password"
}

variable "superuser_new_password" {
  type      = string
  # NB the password will be reset by the cloudbase-init SetUserPasswordPlugin plugin.
  # NB this value must meet the Windows password policy requirements.
  #    see https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/password-must-meet-complexity-requirements
  # Password with @ symbol has issues in cloudbase-init scripts escape-sequencing in terraform ".tf" files
  default = "HeyH0Password"
}

variable "administrator_username" {
  type    = string
  default = "Administrator"
}

variable "administrator_old_password" {
  type      = string
  # NB the password will be reset by the cloudbase-init SetUserPasswordPlugin plugin.
  # NB this value must meet the Windows password policy requirements.
  #    see https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/password-must-meet-complexity-requirements
  # Password with @ symbol has issues in cloudbase-init scripts escape-sequencing in terraform ".tf" files
  default = "HeyH0Password"
}

variable "administrator_new_password" {
  type      = string
  # NB the password will be reset by the cloudbase-init SetUserPasswordPlugin plugin.
  # NB this value must meet the Windows password policy requirements.
  #    see https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/password-must-meet-complexity-requirements
  # Password with @ symbol has issues in cloudbase-init scripts escape-sequencing in terraform ".tf" files
  default = "HeyH0Password"
}

variable "proxmox_datastore_id" {
  type = string
}

variable "proxmox_vm_template_tags" {
  type = list(string)
}

variable "proxmox_vm_tags" {
  type = list(string)
}

variable "vm_fixed_ip" {
  type = string
}

variable "vm_fixed_gateway" {
  type = string
}

variable "vm_fixed_dns" {
  type = list(string)
}

variable "vm_mac_address" {
  type = string
} 

variable "cpu_core_count" {
  type = number
}

variable "memory_size" {
  type = string
  validation {
    condition     = (endswith(var.memory_size, "G") ? 1024 * tonumber(replace(var.memory_size, "G", "")) : ( endswith(var.memory_size, "M") ? tonumber(replace(var.memory_size, "M", "")) : tonumber(var.memory_size) ) ) >= 4 * 1024
    error_message = "memory_size must be a string ending with 'M' or 'G', and at least 4G, e.g., '4096M' or '4G'."
  }
}

variable "disk_size_boot" {
  type = string
  validation {
    condition     = (endswith(var.disk_size_boot, "G") ? tonumber(replace(var.disk_size_boot, "G", "")) : ( endswith(var.disk_size_boot, "M") ? tonumber(replace(var.disk_size_boot, "M", "")) : tonumber(var.disk_size_boot) ) ) >= 32
    error_message = "disk_size_boot must be a string ending with 'M' or 'G', and at least 32G, e.g., '32G' or '32768M'."
  }
}

variable "disk_boot_ssd_enabled" {
  type = bool
}

variable "additional_disks" {
  description = "Optional empty data disks to add during clone. Example interface values: sata1, sata2, scsi1."
  type = list(object({
    interface    = string
    size         = string
    ssd_enabled  = optional(bool, false)
    datastore_id = optional(string)
    file_format  = optional(string, "qcow2")
    discard      = optional(string, "on")
    iothread     = optional(bool, true)
  }))
  default = []

  validation {
    condition = alltrue([
      for d in var.additional_disks :
      d.interface != "sata0"
    ])
    error_message = "additional_disks interfaces must not use sata0 because it is reserved for the boot disk."
  }

  validation {
    condition = length(distinct([
      for d in var.additional_disks :
      lower(d.interface)
    ])) == length(var.additional_disks)
    error_message = "additional_disks interfaces must be unique (for example: sata1, sata2, scsi1)."
  }

  validation {
    condition = alltrue([
      for d in var.additional_disks :
      (endswith(d.size, "G") ? tonumber(replace(d.size, "G", "")) : (endswith(d.size, "M") ? tonumber(replace(d.size, "M", "")) / 1024 : tonumber(d.size) / 1024)) >= 1
    ])
    error_message = "Each additional_disks.size must be at least 1G, e.g. '20G' or '20480M'."
  }
}

variable "cpu_type_host" {
  type = bool
}

variable "podman_installed" {
  type = bool
}

variable "enable_winrm_local_account_remote_login_policy" {
  type = bool
  default = true
}
