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
}

variable "disk_size_boot" {
  type = string
}

variable "disk_boot_ssd_enabled" {
  type = bool
}

variable "cpu_type_host" {
  type = bool
}

variable "podman_installed" {
  type = bool
}
