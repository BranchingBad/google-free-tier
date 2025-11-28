#!/bin/bash
#
# This startup script is executed when the VM boots up.

set -e

echo "--- Startup Script Initiated ---"

# 1. Fetch secrets from Secret Manager
echo "Fetching secrets..."
DUCKDNS_TOKEN=$(gcloud secrets versions access latest --secret="duckdns_token")
EMAIL_ADDRESS=$(gcloud secrets versions access latest --secret="email_address")
DOMAIN_NAME=$(gcloud secrets versions access latest --secret="domain_name")
GCS_BUCKET_NAME=$(gcloud secrets versions access latest --secret="gcs_bucket_name")
BACKUP_DIR=$(gcloud secrets versions access latest --secret="backup_dir")

# 2. Download setup scripts from GCS
# The default Debian image does not have these files locally. 
# We fetch them from the bucket where Terraform uploaded them.
echo "Downloading setup scripts from gs://${GCS_BUCKET_NAME}/setup-scripts/..."
mkdir -p /tmp/2-host-setup
gsutil cp -r "gs://${GCS_BUCKET_NAME}/setup-scripts/*" /tmp/2-host-setup/
chmod +x /tmp/2-host-setup/*.sh

# 3. Run setup scripts
echo "Running setup scripts..."
sudo /tmp/2-host-setup/1-create-swap.sh
sudo /tmp/2-host-setup/2-install-nginx.sh
sudo /tmp/2-host-setup/3-setup-duckdns.sh "$DOMAIN_NAME" "$DUCKDNS_TOKEN"
sudo /tmp/2-host-setup/4-setup-ssl.sh "$DOMAIN_NAME" "$EMAIL_ADDRESS"
sudo /tmp/2-host-setup/5-adjust-firewall.sh
sudo /tmp/2-host-setup/6-setup-backups.sh "$GCS_BUCKET_NAME" "$BACKUP_DIR"
sudo /tmp/2-host-setup/7-setup-security.sh

echo "--- Startup Script Complete ---"