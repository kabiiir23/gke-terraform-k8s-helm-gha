variable "k8s-network" {
}

variable "k8s-subnetwork" {
}

variable "gcp-project-id" {
  type = string
}

variable "service-account" {
  type = string
}

variable "gke-cluster-name" {
  type = string
}

variable "master-ipv4-cidr-block" {
  type = string

}

variable "node-pools" {
  nullable    = true
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
