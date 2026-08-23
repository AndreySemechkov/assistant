output "vm_name" {
  description = "Name of the VM instance"
  value       = google_compute_instance.openclaw.name
}

output "vm_zone" {
  description = "Zone of the VM instance"
  value       = google_compute_instance.openclaw.zone
}

output "vm_internal_ip" {
  description = "Internal IP of the VM"
  value       = google_compute_instance.openclaw.network_interface[0].network_ip
}

output "vm_machine_type" {
  description = "Machine type (e2-micro = free tier)"
  value       = google_compute_instance.openclaw.machine_type
}

output "data_disk_name" {
  description = "Name of the attached data disk"
  value       = google_compute_disk.openclaw_data.name
}

output "data_disk_size_gb" {
  description = "Size of the data disk in GB"
  value       = google_compute_disk.openclaw_data.size
}

# TODO: Uncomment if backup is enabled
# output "snapshot_policy_name" {
#   description = "Name of the daily snapshot backup policy"
#   value       = google_compute_resource_policy.openclaw_backup.name
# }

output "service_account_email" {
  description = "Email of the VM service account"
  value       = google_service_account.openclaw.email
}

output "ssh_tunnel_command" {
  description = "Command to establish SSH tunnel via IAP"
  value       = "gcloud compute ssh ${google_compute_instance.openclaw.name} --zone=${google_compute_instance.openclaw.zone} --tunnel-through-iap -- -L 18789:localhost:18789 -L 18793:localhost:18793 -L 18791:localhost:18791"
}

output "project_id" {
  description = "Project ID (needed for gcloud commands)"
  value       = var.project_id
}

output "container_image" {
  description = "Docker image running on the VM"
  value       = var.container_image
}

output "docker_run_args" {
  description = "Docker run arguments"
  value       = join(" ", var.docker_run_args)
}
