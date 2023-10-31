gcp-region = 
gcp-project-id =
gcp-credentials-file = 

tfstate-bucket-name = "prod-tfstate-bucket"
tfstate-bucket-location = "US"

gke-cluster-name = 
cluster-node-pools = [{
    name         = "node-app"
    machine_type = "e2-medium"
    min_nodes    = 1
    max_nodes    = 3
    labels = {
      pool = "node-app"
    }
    },
    {
      name         = "rabbitmq"
      machine_type = "e2-medium"
      min_nodes    = 1
      max_nodes    = 1
      labels = {
        pool = "rabbitmq"
      }
    },
    {
      name         = "redis"
      machine_type = "e2-highmem-2"
      min_nodes    = 1
      max_nodes    = 1
      labels = {
        pool = "redis"
      }
    },
    {
      name         = "react-app-spa"
      machine_type = "e2-medium"
      min_nodes    = 1
      max_nodes    = 3
      labels = {
        pool = "react-app-spa"
      }
    }
  ]