# Output Public IP
output "vm_public_ip" {
  description = "The public IP address of the VM"
  value       = azurerm_public_ip.pip.ip_address
}

output "vm_username" {
  value = var.vm_username
}

# To use the public key somewhere, you can refer to:
# tls_private_key.ssh_key.public_key_openssh

output "public_key" {
  value = tls_private_key.ssh_key.public_key_openssh
}

output "private_key_pem" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}
