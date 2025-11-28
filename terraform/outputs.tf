output "instance_name" {
  description = "The name of the GCE instance."
  value       = one(google_compute_instance.default[*].name)
}

output "instance_public_ip" {
  description = "The public IP address of the GCE instance."
  value       = try(google_compute_instance.default[0].network_interface[0].access_config[0].nat_ip, null)
}

output "cloud_run_service_url" {
  description = "The URL of the Cloud Run service."
  value       = one(google_cloud_run_v2_service.default[*].uri)
}

output "gke_cluster_name" {
  description = "The name of the GKE cluster."
  value       = one(google_container_cluster.default[*].name)
}

output "region" {
  description = "The region where the resources are deployed."
  value       = var.region
}