terraform {
  backend "gcs" {
    bucket = "homelab-terraform-state-a1b2c3"
    prefix = "openclaw/terraform.tfstate"
  }
}
