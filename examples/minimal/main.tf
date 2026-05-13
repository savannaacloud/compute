terraform {
  required_providers {
    sws = { source = "savannaacloud/sws", version = "~> 0.4" }
  }
}

# Smallest possible footprint: 1 instance + 1 keypair. Nothing else.
# Useful for verifying that your auth + network is wired correctly
# before you turn on the larger module.

variable "network_id" {
  type        = string
  description = "Existing network ID."
}

variable "ssh_public_key_file" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}

resource "sws_keypair" "demo" {
  name       = "compute-minimal"
  public_key = file(pathexpand(var.ssh_public_key_file))
}

resource "sws_instance" "vm" {
  name       = "compute-minimal-vm"
  plan       = "m1.small"
  image      = "Ubuntu 22.04 LTS"
  network_id = var.network_id
  keypair    = sws_keypair.demo.name
  public_ip  = true
}

output "ssh" {
  value = "ssh -i compute-minimal.pem ubuntu@${sws_instance.vm.ip_address}"
}
