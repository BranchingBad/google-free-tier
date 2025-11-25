# ☁️ google-free-tier

Setup and configure a web server on a Google Cloud Free Tier `e2-micro` VM.

This project contains scripts and configurations to automate the setup of a basic web server. You can choose between a manual setup process using shell scripts or an automated approach using Terraform.

- **Manual Setup (Phases 1-3):** Ideal for understanding the step-by-step process of setting up a server.
- **Terraform Setup (Phase 4):** A declarative and automated way to provision your infrastructure.

---

## Phase 1: 🏗️ Google Cloud Setup (Manual)

These commands and scripts should be run from your **local machine**, which has the [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) installed and authenticated.

### 1. Create the VM Instance 💻

This command creates a new `e2-micro` instance (part of the free tier) running Debian 12. The contents of this command are in `1-gcp-setup/1-create-vm.txt`.

```bash
# From your local machine
gcloud compute instances create free-tier-vm \
    --machine-type=e2-micro \
    --zone=us-east1-b \
    --image-family=debian-12 \
    --image-project=debian-cloud \
    --boot-disk-size=30GB \
    --boot-disk-type=pd-standard \
    --boot-disk-auto-delete
```

### 2. Open Firewall Ports 🔥

This command adds network tags to the VM, allowing HTTP and HTTPS traffic. The contents of this command are in `1-gcp-setup/2-open-firewall.txt`.

```bash
# From your local machine
gcloud compute instances add-tags free-tier-vm \
    --tags=http-server,https-server \
    --zone=us-east1-b
```

### 3. Setup Monitoring and Alerting 📊 (Optional)

The free tier includes Cloud Monitoring. This guided script sets up an alert to notify you via email if your website goes down. It will prompt you for an email address and the domain to monitor.

```bash
# From your local machine
bash ./1-gcp-setup/3-setup-monitoring.sh
```
⚠️ **Important:** You will be sent an email to verify the notification channel. You must click the link in this email to activate the alerts.


## Phase 2: ⚙️ Host VM Setup (Manual)

SSH into your new VM to run these scripts.

```bash
gcloud compute ssh free-tier-vm --zone=us-east1-b
```

The scripts in `2-host-setup/` are numbered for clarity. It is recommended to run them in order. They are **idempotent**, meaning they can be safely re-run without causing issues.

### 1. Create Swap File 💾 (Optional, but Recommended)
The `e2-micro` has very little RAM. This creates a 2GB swap file to prevent the server from crashing.

```bash
# On the VM
sudo bash ./2-host-setup/1-create-swap.sh
```

### 2. Install Nginx 🌐
Installs and enables the Nginx web server.

```bash
# On the VM
sudo bash ./2-host-setup/2-install-nginx.sh
```

### 3. Setup DuckDNS 🦆 (Optional)
Sets up a cron job to automatically update your DuckDNS domain. You will be prompted for your subdomain and token.

```bash
# On the VM
bash ./2-host-setup/3-setup-duckdns.sh
```

### 4. Setup SSL 🔒 (Let's Encrypt)
Installs a free SSL certificate from Let's Encrypt. It performs a DNS pre-flight check to ensure your domain is pointing to the server.

```bash
# On the VM
sudo bash ./2-host-setup/4-setup-ssl.sh
```

### 5. Adjust Local Firewall 🛡️ (Optional)
If you use `ufw` on the VM, this opens the necessary ports for Nginx. It automatically checks if `ufw` is active.

```bash
# On the VM
sudo bash ./2-host-setup/5-adjust-firewall.sh
```

### 6. Setup Automated Backups 📦 (Optional)
This script sets up a daily cron job to back up a directory of your choice to a Google Cloud Storage bucket. It will prompt you for the directory path and the GCS bucket name.

```bash
# On the VM
sudo bash ./2-host-setup/6-setup-backups.sh
```
⚠️ **Important:** Before running, you must create the GCS bucket and ensure your VM has permission to write to it. This is typically configured by default.

### 🚀 Advanced Usage: Automation

The `setup_duckdns.sh` and `setup_ssl.sh` scripts can accept arguments to bypass the interactive prompts:

```bash
# Example for DuckDNS
bash ./2-host-setup/3-setup-duckdns.sh "your-domain" "your-token"

# Example for SSL
sudo bash ./2-host-setup/4-setup-ssl.sh "your-domain.duckdns.org" "your-email@example.com"
```

## Phase 3: 🚀 Deploying to GKE (Advanced)

For a more modern, cloud-native approach, you can deploy a containerized application using the free tier of **Google Kubernetes Engine (GKE)**. This phase uses GKE's "Autopilot" mode, where Google manages the underlying infrastructure for you.

The `3-gke-deployment/` directory contains a sample "Hello World" Node.js application, a `Dockerfile` to containerize it, and the necessary Kubernetes configuration files.

### Prerequisites

Before running the setup script, you must have the following tools installed on your **local machine**:
- `gcloud` (already used in Phase 1)
- `docker` ([Installation Guide](https://docs.docker.com/get-docker/))
- `kubectl` ([Installation Guide](https://kubernetes.io/docs/tasks/tools/install-kubectl-gcloud/))

### Deploying the Application

The guided script will walk you through the entire process, from creating the GKE cluster to deploying the application.

```bash
# From your local machine
bash ./3-gke-deployment/setup-gke.sh
```
The script will prompt you to run a few `docker` commands in a separate terminal. Follow the on-screen instructions carefully. This process includes building the container image and pushing it to Google's Artifact Registry.

Once complete, the script will provide you with the command to watch for your service's public IP address.

---

## Phase 4: 🤖 Automated Deployment with Terraform

The `terraform/` directory contains a Terraform project to provision the entire infrastructure, including the GCE instance, firewall rules, monitoring, and GKE cluster.

### Prerequisites

- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed on your local machine.
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) installed and authenticated.

### Configuration

1.  **Backend Setup:** The Terraform project is configured to use a Google Cloud Storage bucket as a backend to store the state file. You need to create this bucket first.
    ```bash
    gsutil mb gs://your-terraform-state-bucket-name
    ```
2.  **Configuration File:** Create a `terraform.tfvars` file in the `terraform/` directory. This file will contain your project-specific variables.
    ```hcl
    project_id      = "your-gcp-project-id"
    region          = "us-east1"
    zone            = "us-east1-b"
    email_address   = "your-email@example.com"
    domain_name     = "your-domain.com"
    duckdns_token   = "your-duckdns-token"
    gcs_bucket_name = "your-backup-bucket-name"
    backup_dir      = "/var/www/html"
    tf_state_bucket = "your-terraform-state-bucket-name"
    gke_cluster_name = "my-gke-cluster"
    image_tag       = "latest"
    ```
3.  **Backend Configuration:** In `terraform/backend.tf`, uncomment the backend configuration and replace the placeholder with your bucket name.
    ```hcl
    terraform {
      backend "gcs" {
        bucket = "your-terraform-state-bucket-name"
        prefix = "terraform/state"
      }
    }
    ```

### Deployment

1.  **Initialize Terraform:** Navigate to the `terraform/` directory and run `terraform init`.
    ```bash
    cd terraform
    terraform init
    ```
2.  **Plan and Apply:** Review the execution plan and then apply the changes.
    ```bash
    terraform plan
    terraform apply
    ```

### Cleanup

To tear down the resources created by Terraform, run the `destroy` command.

```bash
terraform destroy
```
