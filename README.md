# ☁️ google-free-tier

Setup and configure a web server on a Google Cloud Free Tier `e2-micro` VM, or deploy containerized applications using Cloud Run and GKE Autopilot.

This project offers multiple paths for deployment:
- **Manual Setup (Phases 1-2):** Step-by-step shell scripts to configure a VM.
- **Serverless (Phase 3):** Deploy a container to Cloud Run.
- **Kubernetes (Phase 4):** Deploy a container to GKE Autopilot.
- **Terraform (Phase 5):** Fully automated Infrastructure-as-Code provisioning.

---

## 📋 Prerequisites

Before starting, ensure you have the following installed on your **local machine**:

- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) (`gcloud`) - authenticated with your GCP account
- [Docker](https://docs.docker.com/get-docker/) - for containerized deployments (Phases 3-5)
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) - for Infrastructure as Code (Phase 5)
- Git - to clone this repository
- Active GCP account with billing enabled (required even for free tier resources)

**Important:** Even though this guide focuses on free tier resources, you must have billing enabled on your GCP project. Set up billing alerts to avoid unexpected charges.

---

## 💰 Cost Considerations

**Free Tier Resources:**
- 1 `e2-micro` VM instance (744 hours/month in select regions)
- 30GB standard persistent disk storage
- Cloud Run (2 million requests/month, 360,000 GB-seconds/month)
- Cloud Build (120 build-minutes/day)
- Cloud Monitoring (first 150 MB of logs per month)

**Resources That May Incur Costs:**
- **GKE Autopilot**: While there's no cluster management fee, you pay for the compute resources (vCPU/RAM) your pods use
- Cloud Storage (beyond 5GB per month)
- Network egress (beyond 1GB per month from North America)
- Cloud Functions (beyond free tier limits)

**Recommendation:** 
- Enable billing budgets and alerts in GCP Console
- Review the [GCP Free Tier documentation](https://cloud.google.com/free/docs/free-cloud-features)
- The included Cost Killer function (Phase 5) can help prevent overages

---

## Phase 1: 🏗️ Google Cloud Setup (Manual)

Run these commands from your **local machine** to prepare your GCP environment.

### 1. Create the VM Instance 💻

Creates an `e2-micro` instance running Debian 12.

```bash
# See 1-gcp-setup/1-create-vm.txt for the full command
gcloud compute instances create free-tier-vm \
  --machine-type=e2-micro \
  --zone=us-central1-a \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --boot-disk-size=30GB \
  --boot-disk-type=pd-standard \
  --boot-disk-auto-delete
```

**Validation:** Verify the VM is running:
```bash
gcloud compute instances list
```

### 2. Open Firewall Ports 🔥

Allows HTTP and HTTPS traffic to the VM.

```bash
# See 1-gcp-setup/2-open-firewall.txt
gcloud compute instances add-tags free-tier-vm \
  --tags=http-server,https-server \
  --zone=us-central1-a
```

**Validation:** Check that firewall rules are applied:
```bash
gcloud compute firewall-rules list --filter="targetTags:http-server"
```

### 3. Setup Monitoring and Alerting 📊

Sets up an uptime check and email alerts if your site goes down.

```bash
bash ./1-gcp-setup/3-setup-monitoring.sh
```

This script will prompt you for:
- Email address for alerts
- Domain name to monitor

### 4. Create Secrets 🤫

Interactively creates secrets (DuckDNS token, Email, etc.) in Google Secret Manager.

```bash
bash ./1-gcp-setup/4-create-secrets.sh
```

**Note:** These secrets are used by Terraform and Cloud Build configurations.

### 5. Create Artifact Registry 🐳

Creates the Docker repository required for Cloud Run and GKE deployments.

```bash
bash ./1-gcp-setup/5-create-artifact-registry.sh
```

This creates a Docker repository in Artifact Registry where your container images will be stored.

---

## Phase 2: ⚙️ Host VM Setup (Manual)

SSH into your VM and run these scripts from the `2-host-setup/` directory.

```bash
gcloud compute ssh free-tier-vm --zone=us-central1-a
```

Once connected, clone this repository on the VM:
```bash
git clone https://github.com/BranchingBad/google-free-tier.git
cd google-free-tier
```

The scripts in `2-host-setup/` are numbered for clarity. Run them in order. They are idempotent (can be safely re-run).

### 1. Create Swap File 💾

Creates a 2GB swap file to support the 1GB RAM limit of the e2-micro.

```bash
sudo bash ./2-host-setup/1-create-swap.sh
```

**Validation:** Check swap is active:
```bash
free -h
swapon --show
```

### 2. Install Nginx 🌐

Installs and enables the web server.

```bash
sudo bash ./2-host-setup/2-install-nginx.sh
```

**Validation:** Visit your VM's external IP in a browser:
```bash
curl http://$(curl -s ifconfig.me)
```

### 3. Setup DuckDNS 🦆

Configures a cron job to keep your dynamic DNS updated.

```bash
bash ./2-host-setup/3-setup-duckdns.sh
```

Or provide arguments to skip prompts:
```bash
bash ./2-host-setup/3-setup-duckdns.sh "your-subdomain" "your-duckdns-token"
```

**Validation:** Check the cron job:
```bash
crontab -l | grep duckdns
```

### 4. Setup SSL 🔒

Installs Let's Encrypt SSL certificates using Certbot.

```bash
sudo bash ./2-host-setup/4-setup-ssl.sh
```

Or with arguments:
```bash
sudo bash ./2-host-setup/4-setup-ssl.sh "your-domain.duckdns.org" "your-email@example.com"
```

**Important:** Ensure your domain is pointing to your server before running this script. The script performs a DNS pre-flight check.

**Validation:** Test SSL certificate:
```bash
curl https://your-domain.duckdns.org
```

### 5. Adjust Local Firewall 🛡️

Configures `ufw` to allow Nginx traffic (if active).

```bash
sudo bash ./2-host-setup/5-adjust-firewall.sh
```

This script automatically checks if `ufw` is active before making changes.

### 6. Setup Automated Backups 📦

Configures a daily cron job to back up your site to Google Cloud Storage.

```bash
# Interactive mode
sudo bash ./2-host-setup/6-setup-backups.sh

# With arguments
sudo bash ./2-host-setup/6-setup-backups.sh "your-backup-bucket-name" "/var/www/html"
```

**Note:** You must create the GCS bucket first:
```bash
gsutil mb gs://your-backup-bucket-name
```

**Validation:** Check the backup cron job:
```bash
sudo crontab -l | grep backup
```

### 7. Harden Security 🛡️

Installs Fail2Ban and configures unattended security updates.

```bash
sudo bash ./2-host-setup/7-setup-security.sh
```

**Validation:** Check Fail2Ban status:
```bash
sudo fail2ban-client status
```

### 8. Install Ops Agent 📈

Installs the Google Cloud Ops Agent to monitor Memory and Swap usage (metrics not available by default).

```bash
sudo bash ./2-host-setup/8-setup-ops-agent.sh
```

This enables enhanced monitoring in Cloud Console for memory and swap metrics.

**Validation:** Check agent status:
```bash
sudo systemctl status google-cloud-ops-agent
```

---

## Phase 3: 🚀 Cloud Run Deployment (Serverless)

Deploy a Node.js application to **Google Cloud Run** (Free Tier eligible).

The `3-cloud-run-deployment/` directory contains a sample "Hello World" Node.js application and a `Dockerfile`.

### Prerequisites
- Docker installed on your local machine
- Artifact Registry created (Phase 1, Step 5)

### Deploy to Cloud Run

```bash
# From your local machine
bash ./3-cloud-run-deployment/setup-cloud-run.sh
```

This script will:
1. Build the Docker container image
2. Push it to Google Artifact Registry
3. Deploy the service to Cloud Run

The script will prompt you to run a few `docker` commands in a separate terminal. Follow the on-screen instructions carefully.

**Validation:** Once complete, the script provides the URL of your service:
```bash
gcloud run services describe hello-world --region=us-central1 --format='value(status.url)'
```

---

## Phase 4: ☸️ GKE Autopilot Deployment (Kubernetes)

Deploy a Node.js application to **GKE Autopilot**.

⚠️ **Cost Warning:** While GKE Autopilot eliminates the cluster management fee, the compute resources (vCPU/RAM) used by your pods are billed. A basic deployment typically costs $20-30/month.

### Prerequisites
- Docker installed
- Artifact Registry created
- Terraform installed (the script uses Terraform for cluster provisioning)

### Deploy to GKE

```bash
# From your local machine
bash ./4-gke-deployment/setup-gke.sh
```

This script will:
1. Build and push the Docker image
2. Use Terraform to provision the GKE Autopilot cluster
3. Apply Kubernetes manifests to deploy your application

**Validation:** Check your deployment:
```bash
kubectl get pods
kubectl get services
```

**Cleanup:** To avoid ongoing charges:
```bash
cd 4-gke-deployment/terraform
terraform destroy
```

---

## Phase 5: 🤖 Terraform (Infrastructure as Code)

The `terraform/` directory automates the creation of all infrastructure including VM, GKE cluster, Cloud Run services, monitoring, and "Cost Killer" logic.

### Prerequisites
- Terraform installed on your local machine
- Google Cloud SDK authenticated
- All secrets created (Phase 1, Step 4)

### 1. Bootstrap State Bucket

Before running the main Terraform configuration, create a GCS bucket to store Terraform state.

```bash
cd terraform/bootstrap
terraform init
terraform apply
```

This creates a versioned GCS bucket for storing Terraform state files securely.

### 2. Configure Variables

Create a `terraform/terraform.tfvars` file in the main `terraform/` directory:

```hcl
project_id      = "your-gcp-project-id"
region          = "us-central1"
zone            = "us-central1-a"
email_address   = "your-email@example.com"
duckdns_token   = "your-duckdns-token"
domain_name     = "your-domain.duckdns.org"
gcs_bucket_name = "your-backup-bucket"
backup_dir      = "/var/www/html"
tf_state_bucket = "your-tf-state-bucket-name"  # Created in step 1
image_tag       = "latest"

# Feature Flags - Enable/disable components
enable_vm        = true   # Deploy the e2-micro VM
enable_cloud_run = true   # Deploy Cloud Run service
enable_gke       = false  # Deploy GKE cluster (costs $20-30/month)
```

**Security Note:** Never commit `terraform.tfvars` to version control. Add it to `.gitignore`.

### 3. Initialize Terraform

Navigate to the `terraform/` directory and initialize:

```bash
cd terraform
terraform init -backend-config="bucket=YOUR_STATE_BUCKET_NAME"
```

Replace `YOUR_STATE_BUCKET_NAME` with the bucket created in step 1.

### 4. Plan and Apply

Review the execution plan:
```bash
terraform plan
```

If everything looks correct, apply the changes:
```bash
terraform apply
```

Type `yes` when prompted to create the resources.

### 5. Verify Deployment

After Terraform completes:

```bash
# Check VM
gcloud compute instances list

# Check Cloud Run (if enabled)
gcloud run services list

# Check GKE (if enabled)
gcloud container clusters list
```

### 💸 Cost Killer Function

The Terraform configuration includes a "Cost Killer" Cloud Function (`terraform/budget.tf`).

**How it works:**
- Monitors your GCP billing via Pub/Sub notifications
- If spending exceeds your budget (default: $5/month)
- Automatically stops the VM to prevent overages
- Sends email notification

**Configuration:**
```hcl
# In terraform/terraform.tfvars
budget_amount = 5.00  # Monthly budget in USD
```

**Note:** The Cost Killer only stops the VM. GKE and Cloud Run services must be manually disabled if costs exceed expectations.

### Destroy Resources

To tear down all Terraform-managed resources:

```bash
cd terraform
terraform destroy
```

⚠️ **Warning:** This will delete all resources including VMs, databases, and may cause data loss. Ensure you have backups.

---

## 🧹 Cleanup / Teardown

### Manual Setup Cleanup (Phases 1-2)

```bash
# Delete the VM
gcloud compute instances delete free-tier-vm --zone=us-central1-a

# Delete monitoring alert policies
gcloud alpha monitoring policies list
gcloud alpha monitoring policies delete POLICY_ID

# Delete secrets
gcloud secrets delete duckdns-token
gcloud secrets delete email-address

# Delete artifact registry
gcloud artifacts repositories delete docker-repo --location=us-central1

# Delete backup bucket (will delete all backups!)
gsutil rm -r gs://your-backup-bucket-name
```

### Cloud Run Cleanup (Phase 3)

```bash
# Delete the service
gcloud run services delete hello-world --region=us-central1

# Delete container images
gcloud artifacts docker images delete \
  us-central1-docker.pkg.dev/PROJECT_ID/docker-repo/hello-world:latest
```

### GKE Cleanup (Phase 4)

```bash
cd 4-gke-deployment/terraform
terraform destroy
```

Or manually:
```bash
gcloud container clusters delete CLUSTER_NAME --zone=us-central1-a
```

### Terraform Cleanup (Phase 5)

```bash
cd terraform
terraform destroy

# Optionally delete the state bucket
cd bootstrap
terraform destroy
```

---

## 🔧 Advanced: Packer & CI/CD

### Packer

Located in `packer/`, this configuration builds a custom Google Compute Engine image with Nginx, Swap, and security settings pre-installed.

**Benefits:**
- Faster VM provisioning
- Consistent server configuration
- Immutable infrastructure

**Build the image:**
```bash
cd packer
packer init .
packer build template.pkr.hcl
```

**Use the custom image:**
```bash
gcloud compute instances create free-tier-vm \
  --image=your-custom-image \
  --image-project=your-project-id \
  ...
```

### Cloud Build (CI/CD)

The `cloudbuild.yaml` file defines an automated pipeline:

1. **Lint** - Validates shell scripts with shellcheck
2. **Validate** - Checks Terraform syntax
3. **Build** - Creates Docker images for Cloud Run and GKE
4. **Deploy** - Applies Terraform changes automatically

**Setup Cloud Build trigger:**
```bash
gcloud builds triggers create github \
  --repo-name=google-free-tier \
  --repo-owner=YOUR_GITHUB_USERNAME \
  --branch-pattern="^main$" \
  --build-config=cloudbuild.yaml
```

Now every push to the `main` branch will trigger the pipeline.

---

## 🐛 Troubleshooting

### Common Issues

**1. DNS Propagation Delays**
- **Problem:** SSL certificate fails because domain doesn't resolve
- **Solution:** Wait 5-10 minutes after setting up DuckDNS before running SSL script
- **Check:** `nslookup your-domain.duckdns.org`

**2. Insufficient Permissions**
- **Problem:** `gcloud` commands fail with permission errors
- **Solution:** Ensure you have necessary IAM roles (Compute Admin, Storage Admin, etc.)
- **Check:** `gcloud projects get-iam-policy PROJECT_ID`

**3. Swap File Not Activating**
- **Problem:** System still runs out of memory
- **Solution:** Verify swap is enabled: `sudo swapon -a` and check `free -h`

**4. Port 80/443 Already in Use**
- **Problem:** Nginx fails to start
- **Solution:** Check what's using the ports: `sudo lsof -i :80` and kill the process

**5. Docker Permission Denied**
- **Problem:** Cannot connect to Docker daemon
- **Solution:** Add user to docker group: `sudo usermod -aG docker $USER` then logout/login

**6. Terraform State Locked**
- **Problem:** `terraform apply` fails with state lock error
- **Solution:** If you're sure no other process is running: `terraform force-unlock LOCK_ID`

**7. Cost Killer Not Triggering**
- **Problem:** Billing exceeded but VM still running
- **Solution:** Check Cloud Function logs, verify Pub/Sub subscription, ensure IAM permissions

### Getting Help

- Check [GCP Documentation](https://cloud.google.com/docs)
- Open an issue on [GitHub](https://github.com/BranchingBad/google-free-tier/issues)
- Review logs: `journalctl -u nginx` or `gcloud logging read`

---

## 🔒 Security Best Practices

1. **Never commit secrets to Git**
   - Add `terraform.tfvars`, `*.env`, and `*.key` to `.gitignore`
   - Use Secret Manager for all sensitive data

2. **Use least-privilege IAM roles**
   - Don't use Owner role for service accounts
   - Grant only necessary permissions

3. **Enable OS Login**
   ```bash
   gcloud compute instances add-metadata free-tier-vm \
     --metadata enable-oslogin=TRUE
   ```

4. **Regular security updates**
   - The security script enables unattended-upgrades
   - Check regularly: `sudo apt update && sudo apt upgrade`

5. **Monitor access logs**
   - Review Fail2Ban logs: `sudo fail2ban-client status sshd`
   - Check Nginx access logs: `sudo tail -f /var/log/nginx/access.log`

6. **Use strong firewall rules**
   - Only open necessary ports
   - Consider restricting SSH to specific IPs

7. **Enable 2FA on your GCP account**

---

## 📝 Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

Please ensure:
- Shell scripts pass shellcheck linting
- Terraform code is formatted: `terraform fmt`
- Updates to README are clear and accurate

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

## 💬 Support

- **Issues:** [GitHub Issues](https://github.com/BranchingBad/google-free-tier/issues)
- **Discussions:** [GitHub Discussions](https://github.com/BranchingBad/google-free-tier/discussions)
- **Documentation:** This README and inline script comments

---

## 🙏 Acknowledgments

- Google Cloud Platform for the generous free tier
- Let's Encrypt for free SSL certificates
- DuckDNS for free dynamic DNS
- The open-source community for Nginx, Terraform, and all the tools that make this possible