# This file will contain the input variables for the Terraform project.

variable "duckdns_token" {
  description = "The DuckDNS token."
  type        = string
  sensitive   = true
}

variable "email_address" {
  description = "The email address for SSL certificate renewal notices."
  type        = string
}

variable "domain_name" {
  description = "The domain name (e.g., my.duckdns.org)."
  type        = string
}

variable "gcs_bucket_name" {
  description = "The name of the GCS bucket for backups."
  type        = string
}

variable "gke_cluster_name" {
  description = "The name of the GKE cluster."
  type        = string
  default     = "autopilot-cluster-1"
}

variable "image_tag" {
  description = "The tag for the Docker image."
  type        = string
  default     = "latest"
}

variable "tf_state_bucket" {
  description = "The name of the GCS bucket to store the Terraform state. This must be globally unique."
  type        = string
}

variable "backup_dir" {
  description = "The absolute path of the directory to back up."
  type        = string
}
