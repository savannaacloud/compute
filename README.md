# Compute — Savannaa Terraform Module

End-to-end terraform that deploys every **Compute** product on Savannaa from one root module:

| Product | Resource | Notes |
|---|---|---|
| **Instances** | `sws_instance` | Standard VM. Sized via `flavor_name`, attached to your network. |
| **Plans** | `data.sws_plan` | Read-only lookup so you can reference plan sizes by name. |
| **Key Pairs** | `sws_keypair` | SSH keypair; private key returned **once** on create. |
| **Availability Zones** | attribute on `sws_instance` | Pick an AZ inside the region. AWS-style: `ng-abuja-1a` / `ng-lagos-1a`. |
| **Kubernetes** | `sws_kubernetes_template` + `sws_kubernetes_cluster` | Cluster template defines the spec; cluster is the live fleet. Off by default. |
| **Serverless** | `sws_serverless_container` | Single-tenant container — like AWS Fargate. |
| **Big Data** | `sws_kafka` | Managed Kafka brokers. The Savannaa Big Data offering also includes Spark/Flink/Hadoop — those still order via the console wizard. |
| **Auto Scaling** | _(console-only today)_ | Provider doesn't expose `sws_auto_scaling_group` yet. Order at https://savannaa.com/compute/asg. |
| **Dedicated Servers** | _(console-only today)_ | Bare-metal needs inventory checks the API can't do unattended. Order at https://savannaa.com/dedicated-servers. |

---

## Prerequisites

1. A Savannaa account → grab your **API key** from https://savannaa.com/account/api-keys.
2. The **terraform CLI** ≥ 1.5 ([install](https://developer.hashicorp.com/terraform/install)).
3. Your **network ID** and **public-network ID** from the Savannaa console → Networks page.

That's it. The terraform provider auto-installs from the public registry.

---

## Step-by-step

### 1. Clone

```bash
git clone https://github.com/savannaacloud/compute.git
cd compute
```

### 2. Set credentials

```bash
export SWS_API_URL="https://savannaa.com"
export SWS_API_KEY="sws_..."           # from https://savannaa.com/account/api-keys
```

> Tip: drop these into `~/.bashrc` / `~/.zshrc` so future runs pick them up.

### 3. Configure variables

```bash
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars               # set network_id + external_network_id at minimum
```

You can find both IDs in the Savannaa console:

* `network_id` — Networking → Networks → click your network → copy ID.
* `external_network_id` — Networking → Networks → look for the one tagged "external" / "public".

### 4. Initialise

```bash
terraform init
```

This downloads the `savannaacloud/sws` provider plugin from the public Terraform registry.

### 5. Preview

```bash
terraform plan
```

You should see roughly:
* 1 × keypair
* 1 × instance
* 1 × serverless container
* 1 × kafka cluster (if `enable_kafka = true`)
* 1 × k8s template + 1 × k8s cluster (if `enable_kubernetes = true`)

### 6. Apply

```bash
terraform apply
```

Type `yes`. Apply takes:

* **Without k8s:** ~2-4 min.
* **With k8s:** ~10-15 min (Magnum + Heat have to build a fleet).

### 7. Capture the private key (only once!)

```bash
terraform output -raw keypair_private_key > ~/.ssh/compute-demo.pem
chmod 600 ~/.ssh/compute-demo.pem
```

After this run you cannot recover the private key — terraform shows it as `(sensitive value)` in state but you have to use `terraform output` immediately while you remember.

### 8. SSH in

```bash
ssh -i ~/.ssh/compute-demo.pem ubuntu@$(terraform output -raw web_public_ip)
```

(`ubuntu` is the default user for the `Ubuntu 22.04 LTS` image. For other images use the user the console "Connect" panel shows.)

### 9. Verify the rest

```bash
# Serverless container endpoint
terraform output serverless_container_id

# Kafka bootstrap endpoint
terraform output kafka_id

# Kubernetes cluster (only if you set enable_kubernetes = true)
terraform output kubernetes_cluster_id
```

You can also click into them in the Savannaa console at https://savannaa.com/compute.

### 10. Tear down

```bash
terraform destroy
```

Roughly 60 s without k8s, ~5 min with.

---

## Layout

```
compute/
├── README.md                    ← you are here
├── versions.tf                  ← provider pin (sws ~> 0.4)
├── variables.tf                 ← knobs (region, AZ, plans, toggles)
├── main.tf                      ← every Compute resource
├── outputs.tf                   ← keypair, instance IP, kafka/k8s ids
├── terraform.tfvars.example     ← copy → terraform.tfvars and edit
├── .gitignore                   ← keeps state + keys out of the repo
└── examples/
    └── minimal/                 ← 1 instance + 1 keypair only; smoke-test
```

---

## Common gotchas

* **`No valid host was found`** — your region is at compute capacity. Either drop `kubernetes_node_count`, set `enable_kafka = false`, or wait for the auto-healer to free room.
* **`network_id required`** — `terraform.tfvars` not edited; the example placeholder is literally `REPLACE_WITH_YOUR_NETWORK_ID`.
* **`Quota exceeded`** — your project has a 200-instance soft cap. Email support to raise.
* **K8s cluster stuck in `CREATE_IN_PROGRESS`** — first cluster in a brand-new project takes ~10 min while Heat warms the stack template. Subsequent clusters finish in 3-5 min.

---

## Region toggle

Switch between Abuja and Lagos by changing one var:

```hcl
region = "ng-lagos-1"      # was "ng-abuja-1"
```

Each region has independent capacity and pricing.

---

## CI usage

This module is fine inside CI — only `SWS_API_KEY` is sensitive. A typical GitHub Actions step:

```yaml
- uses: hashicorp/setup-terraform@v3
  with: { terraform_version: 1.10.0 }
- run: terraform init && terraform apply -auto-approve
  env:
    SWS_API_URL: https://savannaa.com
    SWS_API_KEY: ${{ secrets.SWS_API_KEY }}
    TF_VAR_network_id: ${{ vars.NETWORK_ID }}
    TF_VAR_external_network_id: ${{ vars.PUBLIC_NETWORK_ID }}
```

---

## Support

* Console: https://savannaa.com/compute
* Docs: https://savannaa.com/docs
* Issues with this module: https://github.com/savannaacloud/compute/issues
