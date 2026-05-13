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

resource "sws_keypair" "demo" {
  name = "compute-minimal"
}

resource "sws_instance" "vm" {
  name        = "compute-minimal-vm"
  flavor_name = "m1.small"
  image_name  = "Ubuntu 22.04 LTS"
  network_id  = var.network_id
  key_name    = sws_keypair.demo.name
}

output "ssh" {
  value = "ssh -i compute-minimal.pem ubuntu@${try(sws_instance.vm.public_ip, sws_instance.vm.ip[0])}"
}
