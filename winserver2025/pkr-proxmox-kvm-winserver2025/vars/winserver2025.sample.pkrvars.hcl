proxmox_host              = "192.168.4.20:8006"
proxmox_ve_endpoint       = "https://192.168.4.20:8006/api2/json"
proxmox_node              = "pve"
proxmox_api_user          = "terraform-prov@pve"
proxmox_api_password      = "CHANGE_ME"
proxmox_insecure_skip_tls_verify = true

storage_iso               = "local"
storage_pool              = "local-lvm"
winserver2025_iso_name    = "Win2025-SERVER_EVAL_x64FRE_en-us.iso"
winserver2025_iso_checksum = "none"
virtio_iso_name           = "virtio-win-0.1.271.iso"
virtio_iso_checksum       = "none"

vm_name                   = "pckr-win2025"
template_name             = "tpl-win2025"
vmid                      = 9999
# cpu_type                  = "host"
cpu_type                  = "x86-64-v2-AES"
cores                     = 2
sockets                   = 1
memory_mb                 = 4096
disk_size                 = "32G"
disk_format               = "qcow2"
disk_ssd_enabled          = true
network_bridge            = "vmbr0"
network_vlan              = ""
network_firewall          = true

administrator_password    = "CHANGE_ME"
windows_time_zone         = "America/Toronto"

winserver2025_enable_openssh                    = false
winserver2025_enable_rdp                        = true
winserver2025_enable_cloudbase_init             = true
winserver2025_enable_virtio_guest_tools         = true
winserver2025_enable_ipconfig_release_before_sysprep = true
winserver2025_enable_sysprep_appx_workaround    = true

vm_image_tags = ["template", "windows", "winserver", "2025"]