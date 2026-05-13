output "plans_visible" {
  description = "Plans this terraform looked up (sanity check the data source returned data)."
  value = {
    small  = data.sws_plan.small.id
    medium = data.sws_plan.medium.id
  }
}

output "keypair_name" {
  description = "Name of the keypair you'll reference from `ssh -i`."
  value       = sws_keypair.admin.name
}

output "keypair_private_key" {
  description = "PEM-formatted private key. Returned ONLY on create — store securely. Use `terraform output -raw keypair_private_key > ~/.ssh/${var.prefix}.pem && chmod 600` after apply."
  value       = sws_keypair.admin.private_key
  sensitive   = true
}

output "web_instance_id" {
  value = sws_instance.web.id
}

output "web_public_ip" {
  description = "Public IP of the standalone web instance. May be null until the public-IP attach finishes."
  value       = try(sws_instance.web.public_ip, null)
}

output "kubernetes_cluster_id" {
  value       = try(sws_kubernetes_cluster.k8s[0].id, null)
  description = "Kubernetes cluster id (only set when var.enable_kubernetes=true)."
}

output "kafka_id" {
  value       = try(sws_kafka.events[0].id, null)
  description = "Kafka cluster id (only set when var.enable_kafka=true)."
}

output "serverless_container_id" {
  value = sws_serverless_container.fn.id
}
