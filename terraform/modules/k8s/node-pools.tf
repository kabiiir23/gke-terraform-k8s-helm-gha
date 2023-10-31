
resource "google_container_node_pool" "node-pool" {
  count      = length(var.node-pools)
  name       = var.node-pools[count.index].name
  cluster    = google_container_cluster.cluster.id
  node_count = var.node-pools[count.index].min_nodes

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  autoscaling {
    min_node_count = var.node-pools[count.index].min_nodes
    max_node_count = var.node-pools[count.index].max_nodes
  }

  node_config {
    preemptible     = false
    machine_type    = var.node-pools[count.index].machine_type
    service_account = var.service-account
    labels          = length(var.node-pools[count.index].labels) > 0 ? var.node-pools[count.index].labels : {}
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only"
    ]
  }
}
