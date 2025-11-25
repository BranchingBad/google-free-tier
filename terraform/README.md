# Terraform for Google Free Tier Project

This directory contains a Terraform project to deploy the resources from the `google-free-tier` project.

## Prerequisites

1.  **Google Cloud Project:** You need to have a Google Cloud project with billing enabled.
2.  **gcloud CLI:** You need to have the `gcloud` CLI installed and configured to use your project.
3.  **Terraform:** You need to have Terraform installed locally.
4.  **Git Repository:** Your project should be in a Git repository connected to Google Cloud Build (e.g., GitHub, Cloud Source Repositories).

## Setup
The setup is a multi-step process.

### 1. Configure Remote State (GCS Backend)
First, we will configure a remote backend to securely store the Terraform state file in a Google Cloud Storage (GCS) bucket.

1.  **Choose a unique bucket name:** The GCS bucket name must be **globally unique**. A good practice is to use your project ID as a prefix (e.g., `your-gcp-project-id-tf-state`).

2.  **Update `terraform.tfvars`:** Add the chosen bucket name to your `terraform/terraform.tfvars` file.
    ```hcl
    tf_state_bucket = "your-globally-unique-bucket-name"
    ```

3.  **Create the bucket:** Run the following commands from the project root directory. This is the **only time** you will run `apply` before the backend is fully configured.
    ```bash
    cd terraform
    terraform init
    terraform apply
    ```
    Approve the plan to create the storage bucket.

4.  **Configure the backend:** This step will be performed by the assistant after you confirm the bucket is created.

### 2. Initial Deployment
After the backend is configured, you can proceed with the initial deployment.

**Create a `terraform.tfvars` file:**
If you haven't already, complete your `terraform.tfvars` file with all required secrets. This file should **not** be committed to your repository.
```hcl
project_id      = "your-gcp-project-id"
tf_state_bucket = "your-globally-unique-bucket-name" # From the previous step
duckdns_token   = "your-duckdns-token"
email_address   = "your-email@example.com"
domain_name     = "your.duckdns.org"
gcs_bucket_name = "your-backup-bucket"
backup_dir      = "/var/www/html"
```

### 3. Automated Deployment with Cloud Build
This project is configured to use Google Cloud Build for continuous integration and deployment. The `cloudbuild.yaml` file in the root directory defines the pipeline.

**How it works:**
1.  **Trigger:** When you push a commit to your main branch, it automatically triggers a build in Google Cloud Build.
2.  **Build & Push:** Cloud Build builds the Docker image from the `3-gke-deployment/app` directory.
3.  **Tag:** The image is tagged with the short commit SHA of the push that triggered the build.
4.  **Deploy:** Cloud Build then runs `terraform apply`, passing in the new image tag. Terraform updates the GKE deployment with the newly built image.

See the instructions in the previous step for setting up the Cloud Build trigger and permissions.

### 4. Manual Terraform Commands
While Cloud Build handles `terraform apply`, you can still use other Terraform commands locally for inspection:
```bash
# See what changes Terraform will make
terraform plan

# See the current output values
terraform output
```

## Outputs

The Terraform configuration will output the following values:
*   `instance_name`: The name of the GCE instance.
*   `instance_public_ip`: The public IP address of the GCE instance.
*   `gke_cluster_name`: The name of the GKE cluster.
*   `kubernetes_service_ip`: The public IP address of the Kubernetes service.
*   `region`: The GCP region where resources are deployed.

You can get these values by running `terraform output`.
