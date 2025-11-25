terraform {
  backend "gcs" {}
}

resource "google_storage_bucket" "tf_state" {
  name          = var.tf_state_bucket
  location      = "US"
  force_destroy = false

  versioning {
    enabled = true
  }
}
