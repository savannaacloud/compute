locals {
  prefix = var.prefix
}

# ── Network (data source) ──────────────────────────────────────────────────
# Lookup the user's network by name. Every signup gets a "default" network;
# override by setting network_name in tfvars.

data "sws_network" "default" { name = var.network_name }
data "sws_network" "public"  { name = var.external_network_name }

# ── Image (data source) ────────────────────────────────────────────────────
# Look up the image by name → returns its UUID. sws_instance.image needs
# a UUID (it's passed straight to Nova as imageRef).

data "sws_image" "os" {
  name = var.image_name
}

# ── Plans (data source) ─────────────────────────────────────────────────────
# Plans are the Savannaa-branded compute sizes (m1.small etc). They aren't
# created by you — you read them. Use them to size other resources.

data "sws_plan" "small" {
  name = "m1.small"
}

data "sws_plan" "medium" {
  name = "m1.medium"
}

# ── Key Pairs ───────────────────────────────────────────────────────────────
# SSH keypair for any VM-shaped workload (instances, k8s nodes, kafka brokers).
# private_key is returned ONLY on create — store it from outputs.tf or it's lost.

resource "sws_keypair" "admin" {
  name       = "${local.prefix}-admin"
  public_key = file(pathexpand(var.ssh_public_key_file))
}

# ── Instances ──────────────────────────────────────────────────────────────
# Standard VM. availability_zone controls which AZ within the region;
# region is set at the provider level (or per-resource on some).

resource "sws_instance" "web" {
  name       = "${local.prefix}-web"
  plan       = var.instance_plan
  image      = data.sws_image.os.id
  network_id = data.sws_network.default.id
  keypair    = sws_keypair.admin.name
  public_ip  = true
}

# ── Kubernetes (template + cluster) ─────────────────────────────────────────
# Template is the reusable spec; cluster is the actual fleet of nodes.
# Both gated behind a variable because spinning up k8s costs ~10 min.

resource "sws_kubernetes_template" "k8s" {
  count = var.enable_kubernetes ? 1 : 0

  name                = "${local.prefix}-k8s-tpl"
  image               = "Fedora CoreOS 43"
  flavor_id           = "m1.medium"
  master_flavor_id    = "m1.medium"
  external_network_id = data.sws_network.public.id
  keypair_id          = sws_keypair.admin.name
  coe_name            = "kubernetes"
}

resource "sws_kubernetes_cluster" "k8s" {
  count = var.enable_kubernetes ? 1 : 0

  name                = "${local.prefix}-k8s"
  cluster_template_id = sws_kubernetes_template.k8s[0].id
  node_count          = var.kubernetes_node_count
  master_count        = 1
  keypair_id          = sws_keypair.admin.name
}

# ── Serverless Containers ──────────────────────────────────────────────────
# Single-tenant container, like an AWS Fargate task. Image is pulled from
# Savannaa's registry (or any public registry the platform proxies).

resource "sws_serverless_container" "fn" {
  name       = "${local.prefix}-fn"
  image      = "registry.savannaa.com/library/echo:latest"
  network_id = data.sws_network.default.id
}

# ── Big Data (Kafka) ───────────────────────────────────────────────────────
# Kafka is the Big Data showcase — managed broker cluster you stream events
# into. The platform also offers Spark / Flink / Hadoop via the same router
# but only Kafka has a first-class terraform resource today; the rest are
# created via the console wizard.

resource "sws_kafka" "events" {
  count = var.enable_kafka ? 1 : 0

  name = "${local.prefix}-kafka"
  config = jsonencode({
    flavor_id       = "m1.medium"
    broker_count    = 3
    storage_gb      = 50
    network_id      = data.sws_network.default.id
    kafka_version   = "3.7"
  })
}

# ── Auto Scaling Group ──────────────────────────────────────────────────────
# Not yet exposed via terraform (UI-only as of provider v0.4.x). Once the
# sws_auto_scaling_group resource lands you'd write something like:
#
#   resource "sws_auto_scaling_group" "web" {
#     name           = "${local.prefix}-web-asg"
#     min_size       = 1
#     max_size       = 5
#     desired_size   = 2
#     flavor_name    = var.instance_plan
#     image_name     = var.image_name
#     network_id     = data.sws_network.default.id
#     key_name       = sws_keypair.admin.name
#   }
#
# For now create one through the console at https://savannaa.com/compute/asg.

# ── Dedicated Servers (bare metal) ─────────────────────────────────────────
# Bare-metal orders are captured via the console — the underlying physical
# fulfillment requires inventory checks the API can't do unattended. Order
# at https://savannaa.com/dedicated-servers; the provider does NOT yet
# expose a `sws_dedicated_server` resource.
