terraform {
  # backend "gcs" {
  #   bucket = "<YOUR_PROJECT_ID>-tfstate"
  #   prefix = "terraform/state"
  # }
}

# --- Backend Configuration Guide ---
#
# 1. Create the State Bucket:
#    Navigate to terraform/bootstrap and run:
#    $ terraform init
#    $ terraform apply
#    (Enter your project_id when prompted)
#
# 2. Configure this file:
#    Uncomment the 'backend "gcs"' block above.
#    Replace <YOUR_PROJECT_ID> with your actual Google Cloud Project ID.
#
# 3. Initialize Terraform:
#    Navigate back to this directory (terraform/) and run:
#    $ terraform init -reconfigure
#
# 4. Apply Infrastructure:
#    $ terraform apply
#
# Note: Using GCS as a backend supports state locking, which prevents
# concurrent runs from corrupting your state file.