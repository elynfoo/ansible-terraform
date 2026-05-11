variable "resource_group_name" {
  default = "ansible-lab-rg"
}

variable "location" {
  default = "southeastasia"
}

variable "vm_name" {
  default = "ansible-target"
}

variable "admin_username" {
  default = "ansibleuser"
}

variable "ssh_public_key_path" {
  default = "~/.ssh/id_rsa.pub"
}
