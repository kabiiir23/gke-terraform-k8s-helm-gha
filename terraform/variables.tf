variable "tfstate-bucket-name" {
  type = string
}

variable "tfstate-bucket-location" {
  type = string
}

variable "gcp-region" {
  type = string
}

variable "gcp-project-id" {
  type = string
}

variable "gcp-credentials-file" {
  type = string
}

variable "gke-cluster-name" {
  type = string
}

variable "cluster-node-pools" {
  description = "List of node pools"
  type = list(object({
    name         = string
    machine_type = string
    min_nodes    = number
    max_nodes    = number
    labels       = map(string)
  }))
  default = []
}

