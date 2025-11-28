# --- APIs ---
# Ensure necessary APIs are enabled for billing automation
resource "google_project_service" "billing_apis" {
  for_each = toset([
    "billingbudgets.googleapis.com",
    "cloudfunctions.googleapis.com",
    "pubsub.googleapis.com",
    "cloudbuild.googleapis.com",
    "appengine.googleapis.com" # Required for some Gen 1 functions internal logic
  ])
  service            = each.key
  disable_on_destroy = false
}

# --- Pub/Sub Topic for Billing Alerts ---
resource "google_pubsub_topic" "billing_alert_topic" {
  name = "billing-alerts"
  depends_on = [google_project_service.billing_apis]
}

# --- Budget ---
resource "google_billing_budget" "budget" {
  billing_account = var.billing_account_id
  display_name    = "Free Tier Budget Alert"

  budget_filter {
    projects = ["projects/${var.project_id}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = var.budget_amount
    }
  }

  threshold_rules {
    threshold_percent = 0.5
  }
  threshold_rules {
    threshold_percent = 0.9
  }
  threshold_rules {
    threshold_percent = 1.0
  }

  all_updates_rule {
    pubsub_topic = google_pubsub_topic.billing_alert_topic.id
  }

  depends_on = [google_project_service.billing_apis]
}

# --- Cloud Function: Cost Killer ---
# This function shuts down the VM if the budget is exceeded.

# 1. Bucket for Function Source
resource "google_storage_bucket" "functions_bucket" {
  name                        = "${var.project_id}-functions"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

# 2. Archive the Source Code
# Expects source code in terraform/functions/cost-killer/
data "archive_file" "cost_killer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/functions/cost-killer"
  output_path = "${path.module}/functions/cost-killer.zip"
}

# 3. Upload Source to Bucket
resource "google_storage_bucket_object" "cost_killer_zip" {
  name   = "cost-killer-${data.archive_file.cost_killer_zip.output_md5}.zip"
  bucket = google_storage_bucket.functions_bucket.name
  source = data.archive_file.cost_killer_zip.output_path
}

# 4. The Cloud Function
resource "google_cloudfunctions_function" "cost_killer" {
  count                 = var.enable_vm ? 1 : 0
  name                  = "cost-killer"
  description           = "Stops the VM when billing budget is exceeded"
  runtime               = "nodejs20"
  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.functions_bucket.name
  source_archive_object = google_storage_bucket_object.cost_killer_zip.name
  trigger_http          = false
  entry_point           = "stopBilling"
  
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.billing_alert_topic.name
  }

  environment_variables = {
    PROJECT_ID    = var.project_id
    ZONE          = var.zone
    INSTANCE_NAME = google_compute_instance.default[0].name
  }

  depends_on = [google_project_service.billing_apis]
}

# 5. IAM: Allow Function to Stop VM
resource "google_project_iam_member" "cost_killer_sa_compute" {
  count   = var.enable_vm ? 1 : 0
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1" # Required to stop instances
  member  = "serviceAccount:${var.project_id}@appspot.gserviceaccount.com" # Default App Engine SA used by Gen 1 functions
  
  depends_on = [google_cloudfunctions_function.cost_killer]
}