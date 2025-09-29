resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#Save the public key to a file
# resource "local_file" "public_key_file" {
#   content  = tls_private_key.ssh_key.public_key_openssh
#   filename = "${path.module}/id_rsa.pub"
#   file_permission = "0644"
# }

#Save the private key to a file with restricted permissions
resource "local_file" "private_key_file" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/id_rsa"
  file_permission = "0600"
}

#Use locals to reference these paths later
locals {
  public_key_path  = local_file.public_key_file.filename
  private_key_path = local_file.private_key_file.filename
}