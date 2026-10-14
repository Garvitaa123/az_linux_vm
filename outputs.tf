output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "web_vm_public_ip" {
  value = azurerm_public_ip.web_vm.ip_address
}

output "web_vm_private_ip" {
  value = azurerm_network_interface.web_vm.private_ip_address
}

output "web_url" {
  value = "http://${azurerm_public_ip.web_vm.ip_address}"
}

output "ssh_command" {
  value = "ssh -i web-vm-key.pem ${var.admin_username}@${azurerm_public_ip.web_vm.ip_address}"
}

output "bastion_name" {
  value = azurerm_bastion_host.bastion.name
}
