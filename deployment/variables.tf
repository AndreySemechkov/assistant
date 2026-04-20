variable "project_id" {
  description = "ID of the relevant GCP project"
  type        = string
}

variable "region" {
  description = "GCP region to use (free tier: us-west1, us-central1, us-east1)"
  type        = string
  default     = "us-west1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "service_name" {
  description = "Name of the service/VM"
  type        = string
  default     = "openclaw"
}

variable "machine_type" {
  description = "GCE machine type (free tier: e2-micro)"
  type        = string
  default     = "e2-micro"
}

variable "container_image" {
  description = "Full Docker image path including registry prefix (e.g., docker.io/username/image:tag)"
  type        = string
}

variable "docker_run_args" {
  description = "Additional arguments for docker run command"
  type        = list(string)
  default = [
    "--network host",
    "--restart unless-stopped",
    "-v /home/openclaw/.clawdbot:/home/openclaw/.clawdbot",
    "-v /home/openclaw/.openclaw:/home/openclaw/.openclaw",
    "-v /home/openclaw/data:/data",
    "-e HOME=/home/openclaw"
  ]
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB (free tier: 30GB total with data disk)"
  type        = number
  default     = 10
}

variable "data_disk_size_gb" {
  description = "Data disk size in GB for /home/openclaw (free tier: 30GB total with boot disk)"
  type        = number
  default     = 20
}

variable "snapshot_start_time" {
  description = "Time to start daily snapshot (UTC, format: HH:MM)"
  type        = string
  default     = "03:00"
}

variable "snapshot_retention_days" {
  description = "Number of days to retain snapshots (daily schedule = number of snapshots kept)"
  type        = number
  default     = 3
}
