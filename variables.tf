variable "prefix" {
  description = "Prefix for every resource name so multiple environments coexist."
  type        = string
  default     = "compute-demo"
}

variable "region" {
  description = "Savannaa region: ng-abuja-1 or ng-lagos-1."
  type        = string
  default     = "ng-abuja-1"
}

variable "ssh_public_key_file" {
  description = "Path to an existing SSH public key file. The provider's sws_keypair takes a public_key string (BYO key, like AWS); you keep the matching private key on your laptop."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "instance_plan" {
  description = "Plan name for the standalone VM (look up with `data.sws_plan`)."
  type        = string
  default     = "m1.small"
}

variable "image_name" {
  description = "OS image for instances and the bastion."
  type        = string
  default     = "Ubuntu 22.04 LTS"
}

variable "network_name" {
  description = "Name of an existing network (looked up via data.sws_network). Every signup gets a 'default' network automatically — use that unless you've created your own."
  type        = string
  default     = "default"
}

variable "external_network_name" {
  description = "Public/external network name for Kubernetes egress. The platform's external network is named 'public' in both regions."
  type        = string
  default     = "public"
}

variable "enable_kubernetes" {
  description = "Spin up a Kubernetes template + cluster (heavy, ~10 minutes)."
  type        = bool
  default     = false
}

variable "enable_kafka" {
  description = "Spin up a Kafka cluster (the Big Data showcase)."
  type        = bool
  default     = true
}

variable "kubernetes_node_count" {
  description = "Worker count when enable_kubernetes=true."
  type        = number
  default     = 2
}
