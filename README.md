# Google Cloud Free Tier Web Server Setup

Setup and configure a web server on a Google Cloud Free Tier e2-micro VM. This project contains scripts and configurations to automate the setup of a basic web server. You can choose between a manual setup process using shell scripts or an automated approach using Terraform.

## Overview

- **Manual Setup (Phases 1-3)**: Ideal for understanding the step-by-step process of setting up a server
- **Terraform Setup (Phase 4)**: A declarative and automated way to provision your infrastructure

## Prerequisites

These commands and scripts should be run from your local machine, which has the [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) installed and authenticated.

---

## Phase 1: GCP Setup

### Step 1: Create VM Instance

This command creates a new `e2-micro` instance (part of the free tier) running Debian 12. The contents of this command are in `1-gcp-setup/1-create-vm.txt`.

```bash
# From your local machine
gcloud compute instances create free-tier-vm \
  --machine-type=e2-micro \
  --zone=us-central1-a \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --boot-disk-size=30GB \
  --boot-disk-type=pd-standard \
  --boot-disk-auto-delete
```

### Step 2: Configure Firewall

This command adds network tags to the VM, allowing HTTP and HTTPS traffic. The contents of this command are in `1-gcp-setup/2-open-firewall.txt`.

```bash
# From your local machine
gcloud compute instances add-tags free-tier-vm \
  --tags=http-server,https-server \
  --zone=us-central1-a
```

### Step 3: Setup Monitoring

The free tier includes Cloud Monitoring. This guided script sets up an alert to notify you via email if your website goes down. It will prompt you for an email address and the domain to monitor.

```bash
# From your local machine
bash ./1-gcp-setup/3-setup-monitoring.sh
```

### Step 4: Create Secrets

This script will interactively prompt you to create secrets in Google Cloud Secret Manager. These secrets are used by the Terraform and Cloud Build configurations.

```bash
# From your local machine
bash ./1-gcp-setup/4-create-secrets.sh
```

---

## Phase 2: Host Setup

SSH into your new VM to run these scripts:

```bash
gcloud compute ssh free-tier-vm --zone=us-central1-a
```

The scripts in `2-host-setup/` are numbered for clarity. It is recommended to run them in order. They are idempotent, meaning they can be safely re-run without causing issues.

### Step 1: Create Swap File

The `e2-micro` has very little RAM. This creates a 2GB swap file to prevent the server from crashing.

```bash
# On the VM
sudo bash ./2-host-setup/1-create-swap.sh
```

### Step 2: Install Nginx

Installs and enables the Nginx web server.

```bash
# On the VM
sudo bash ./2-host-setup/2-install-nginx.sh
```

### Step 3: Setup DuckDNS

Sets up a cron job to automatically update your DuckDNS domain. You will be prompted for your subdomain and token.

```bash
# On the VM
bash ./2-host-setup/3-setup-duckdns.sh
```

### Step 4: Setup SSL

Installs a free SSL certificate from Let's Encrypt. It performs a DNS pre-flight check to ensure your domain is pointing to the server.

```bash
# On the VM
sudo bash ./2-host-setup/4-setup-ssl.sh
```

### Step 5: Adjust Firewall (Optional)

If you use `ufw` on the VM, this opens the necessary ports for Nginx. It automatically checks if `ufw` is active.

```bash
# On the VM
sudo bash ./2-host-setup/5-adjust-firewall.sh
```

### Step 6: Setup Backups

This script sets up a daily cron job to back up a directory of your choice to a Google Cloud Storage bucket. It can be run interactively or by providing the bucket name and directory as arguments.

```bash
# On the VM (interactive)
sudo bash ./2-host-setup/6-setup-backups.sh

# On the VM (with arguments)
sudo bash ./2-host-setup/6-setup-backups.sh "your-backup-bucket-name" "/var/www/html"
```

### Step 7: Setup Security

Installs and configures Fail2Ban to protect against brute-force attacks.

```bash
# On the VM
sudo bash ./2-host-setup/7-setup-security.sh
```

### Non-Interactive Mode

The `setup_duckdns.sh`, `setup_ssl.sh`, and `setup_backups.sh` scripts can accept arguments to bypass the interactive prompts:

```bash
# Example for DuckDNS
bash ./2-host-setup/3-setup-duckdns.sh "your-domain" "your-token"

# Example for SSL
sudo bash ./2-host-setup/4-setup-ssl.sh "your-domain.duckdns.org" "your-email@example.com"

# Example for Backups
sudo bash ./2-host-setup/6-setup-backups.sh "your-backup-bucket-name" "/var/www/html"
```

---

## Phase 3: Cloud Run Deployment

For a modern, serverless approach, you can deploy a containerized application using Google Cloud Run. This service has a generous free tier and automatically scales to zero, making it a cost-effective choice.

The `3-cloud-run-deployment/` directory contains a sample "Hello World" Node.js application and a `Dockerfile` to containerize it.

### Prerequisites

Before running the setup script, you must have the following tools installed on your local machine:

- `gcloud` (already used in Phase 1)
- `docker` ([Installation Guide](https://docs.docker.com/get-docker/))

### Setup

The guided script will walk you through the entire process, from building the container to deploying it to Cloud Run.

```bash
# From your local machine
bash ./3-cloud-run-deployment/setup-cloud-run.sh
```

The script will prompt you to run a few `docker` commands in a separate terminal. Follow the on-screen instructions carefully. This process includes building the container image and pushing it to Google's Artifact Registry.

Once complete, the script will provide you with the command to find the URL of your service.

---

## Phase 4: Terraform Automation

The `terraform/` directory contains a Terraform project to provision the entire infrastructure, including the GCE instance, firewall rules, monitoring, and the Cloud Run service.

### Prerequisites

- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed on your local machine
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) installed and authenticated

### Setup

1. **Backend Setup**: The Terraform project is configured to use a Google Cloud Storage bucket as a backend to store the state file. You need to create this bucket first.

```bash
gsutil mb gs://your-terraform-state-bucket-name
```

2. **Backend Configuration**: In `terraform/backend.tf`, you will see the backend configuration. You will need to provide the bucket name when you initialize Terraform.

3. **Configuration File**: Create a `terraform.tfvars` file in the `terraform/` directory. This file will contain your project-specific variables.

```hcl
project_id = "your-gcp-project-id"
region = "us-central1"
zone = "us-central1-a"
email_address = "your-email@example.com"
domain_name = "your-domain.com"
duckdns_token = "your-duckdns-token"
gcs_bucket_name = "your-backup-bucket-name"
backup_dir = "/var/www/html"
tf_state_bucket = "your-terraform-state-bucket-name"
image_tag = "latest"
```

4. **Initialize Terraform**: Navigate to the `terraform/` directory and run `terraform init`. You will be prompted to provide the name of the GCS bucket for the backend.

```bash
cd terraform
terraform init
```

5. **Plan and Apply**: Review the execution plan and then apply the changes.

```bash
terraform plan
terraform apply
```

### Destroy Resources

To tear down the resources created by Terraform, run the destroy command:

```bash
terraform destroy
```

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the [MIT License](LICENSE).

## Support

If you encounter any issues or have questions, please open an issue on the GitHub repository.