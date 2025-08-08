# terraform/01-network/main.tf

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.47"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
