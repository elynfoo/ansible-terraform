output "vm_public_ip" {
  value       = azurerm_public_ip.pip.ip_address
  description = "Public IP of the VM — use this in ansible/inventory.ini"
}
