resource "google_storage_bucket" "tfstate-bucket" {
  name     = var.tfstate-bucket-name
  location = var.tfstate-bucket-location

  public_access_prevention = "enforced"

  versioning {
    enabled = true
  }
}
