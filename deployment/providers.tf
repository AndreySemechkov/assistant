provider "google" {
  project = var.project_id
  region  = var.region
}

terraform {
  required_providers {
    google = {
      version = "6.35.0"
      source  = "hashicorp/google"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
  required_version = ">1.9.0"
}
