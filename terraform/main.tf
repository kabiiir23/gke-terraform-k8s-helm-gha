module "vpc" {
  source = "./modules/vpc"
}

resource "google_service_account" "k8s-service-account" {
  account_id   = "kubernetes"
  display_name = "K8s Service Account"
}

resource "google_project_iam_member" "allow_image_pull" {
  project = var.gcp-project-id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.k8s-service-account.email}"
}

module "core-k8s-cluster" {
  source                 = "./modules/k8s"
  k8s-network            = module.vpc.network
  k8s-subnetwork         = module.vpc.subnetwork
  gcp-project-id         = var.gcp-project-id
  service-account        = google_service_account.k8s-service-account.email
  gke-cluster-name       = var.gke-cluster-name
  master-ipv4-cidr-block = "192.168.1.0/28"
  node-pools             = var.cluster-node-pools
}

