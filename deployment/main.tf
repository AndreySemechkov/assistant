# Service account for the VM
resource "google_service_account" "openclaw" {
  account_id   = "${var.service_name}-sa"
  display_name = "OpenClaw VM Service Account"
}

# VPC network for the VM
resource "google_compute_network" "openclaw" {
  name                    = "${var.service_name}-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "openclaw" {
  name          = "${var.service_name}-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.openclaw.id
}

# Firewall: Allow SSH only from your IP
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.service_name}-allow-ssh"
  network = google_compute_network.openclaw.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["${local.my_ip}/32"]
  target_tags   = ["openclaw"]
}

# Firewall: Allow IAP for SSH (backup access method)
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${var.service_name}-allow-iap-ssh"
  network = google_compute_network.openclaw.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP's IP range
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["openclaw"]
}

# Firewall: Deny all other ingress (explicit)
resource "google_compute_firewall" "deny_all" {
  name     = "${var.service_name}-deny-all"
  network  = google_compute_network.openclaw.name
  priority = 65534

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["openclaw"]
}

# Cloud Router + NAT for egress (container pulls, etc.)
resource "google_compute_router" "openclaw" {
  name    = "${var.service_name}-router"
  region  = var.region
  network = google_compute_network.openclaw.id
}

resource "google_compute_router_nat" "openclaw" {
  name                               = "${var.service_name}-nat"
  router                             = google_compute_router.openclaw.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Persistent disk for OpenClaw data (GCP Free Tier: 30GB standard total)
resource "google_compute_disk" "openclaw_data" {
  name = "${var.service_name}-data"
  type = "pd-standard"
  zone = "${var.region}-a"
  size = var.data_disk_size_gb

  labels = {
    environment = var.environment
    app         = var.service_name
  }
}

# TODO: Uncomment backup resources if data becomes useful (not in free tier, ~$1/month)
# # Daily snapshot schedule for data disk backup
# resource "google_compute_resource_policy" "openclaw_backup" {
#   name   = "${var.service_name}-daily-backup"
#   region = var.region
#
#   snapshot_schedule_policy {
#     schedule {
#       daily_schedule {
#         days_in_cycle = 1
#         start_time    = var.snapshot_start_time
#       }
#     }
#
#     retention_policy {
#       max_retention_days    = var.snapshot_retention_days
#       on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
#     }
#
#     snapshot_properties {
#       labels = {
#         environment = var.environment
#         app         = var.service_name
#         backup      = "daily"
#       }
#       storage_locations = [var.region]
#     }
#   }
# }
#
# # Attach snapshot schedule to data disk
# resource "google_compute_disk_resource_policy_attachment" "openclaw_backup" {
#   name = google_compute_resource_policy.openclaw_backup.name
#   disk = google_compute_disk.openclaw_data.name
#   zone = "${var.region}-a"
# }

# Compute Engine VM running OpenClaw (GCP Free Tier: e2-micro)
resource "google_compute_instance" "openclaw" {
  name         = var.service_name
  machine_type = var.machine_type
  zone         = "${var.region}-a"

  tags = ["openclaw"]

  # Boot disk (GCP Free Tier: pd-standard)
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
      size  = var.boot_disk_size_gb
      type  = "pd-standard"
    }
  }

  # Attached data disk for /home/openclaw
  attached_disk {
    source      = google_compute_disk.openclaw_data.id
    device_name = "openclaw-data"
    mode        = "READ_WRITE"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.openclaw.id
    # No external IP - access via SSH tunnel only
  }

  metadata = {
    google-logging-enabled = "true"
    GOOGLE_CLOUD_PROJECT   = var.project_id
    CONTAINER_IMAGE        = var.container_image
    DOCKER_RUN_ARGS        = join(" ", var.docker_run_args)
  }

  metadata_startup_script = file("${path.module}/startup.sh")

  service_account {
    email  = google_service_account.openclaw.email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  allow_stopping_for_update = true
}
