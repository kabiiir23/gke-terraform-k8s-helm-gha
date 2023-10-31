/*
 * This file contains the configuration for the Google Cloud provider and the Google Cloud Storage bucket used as the backend for Terraform state.
 */

provider "google" {
  project = var.gcp-project-id
  region  = var.gcp-region
}

terraform {
  # backend "gcs" {
  #   bucket = "prod-tfstate-bucket"
  #   prefix = "terraform/state"
  # }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}
