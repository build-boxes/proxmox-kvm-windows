
output "ip" {
  #value = coalesce(try(split("/",proxmox_virtual_environment_vm.example.initialization[0].ip_config[0].ipv4[0].address)[0], null),proxmox_virtual_environment_vm.example.ipv4_addresses[index(proxmox_virtual_environment_vm.example.network_interface_names, "Ethernet")][0] )
  #proxmox_virtual_environment_vm.example.ipv4_addresses[index(proxmox_virtual_environment_vm.example.network_interface_names, "Ethernet")][0]
  value = local.host_ip
}