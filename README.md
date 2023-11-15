# Usage

## Create infrastructure

What's included:

- VPC
- Subnet
- router
- NAT
- GKE cluster
- Cluster node pools
- GCS bucket

```bash
# Set environment variables
source .env

# Set Google Cloud project
gcloud config set project $PROJECT_ID

# Get Google Cloud credentials
gcloud auth application-default login

# Install GKE Auth Plugin component for gcloud
gcloud components install gke-gcloud-auth-plugin

# Initializes the Terraform working directory and downloads any necessary plugins.
terraform -chdir=terraform init  -var-file=variables/$ENV.tfvars

# Shows a preview of the changes that Terraform will make to your infrastructure.
terraform -chdir=terraform plan  -var-file=variables/$ENV.tfvars

# Applies the changes to your infrastructure.
terraform -chdir=terraform apply  -var-file=variables/$ENV.tfvars

# Destroys the infrastructure that Terraform manages.
terraform -chdir=terraform destroy  -var-file=variables/$ENV.tfvars

# A GCS bucket will be created. Updtae the backend to use the bucket to store states in _provider.tf file
# Terraform init and apply again to update states in the bucket
# Delete local states after applying changes first time.
rm -rf terraform/.terraform terraform/terraform.tfstate terraform/terraform.tfstate.backup terraform/.terraform.lock.hcl
```

## Push Docker image to GCR

```bash
# Build the Docker image
docker build -t $REGION-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE_NAME:$IMAGE_TAG .

# Authenticate with GCR
gcloud auth configure-docker $REGION-docker.pkg.dev

# Push the Docker image to GCR
docker push $REGION-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE_NAME:$IMAGE_TAG
```

## Create k8s resources

```bash
# Authenticate with the zonal cluster
gcloud container clusters get-credentials $CLUSTER_NAME --zone $CLUSTER_ZONE --project $PROJECT_ID

# Authenticate with the regional cluster
gcloud container clusters get-credentials $CLUSTER_NAME --region $CLUSTER_REGION --project $PROJECT_ID
```

## Helm Approach

### Helm Values files

- `values/$ENV/node.yaml` file contains the configuration for the node js deployment
- `values/$ENV/react-app.yaml` file contains the configuration for the react app deployment
- `node.yaml` and `react-app.yaml` have the same configuration structure.
- `values/rabbitmq.yaml` file contains the configuration for the rabbitmq deployment
- `values/redis.yaml` file contains the configuration for the redis deployment

### Static IP address

If you want to add static IP address to the ingress, follow the steps to create static ip and create a CNAME record for your domain. Then, update ingress.globalStaticIpName in the node.yaml file

```bash
## Create static IP address
gcloud compute addresses create $STATIC_IP_NAME --global
## Get the static IP address
gcloud compute addresses describe $STATIC_IP_NAME --global
```

### SSL certificate

```bash
# Install cert-manager to manage SSL certificates
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager\
   --namespace cert-manager\
   --create-namespace\
   --version v1.13.1

```

### Deploy using Helm

Install helm: <https://helm.sh/docs/intro/install/>

```bash
# If you want to have SSL keep the tls.enabled to false in values file and follow the steps to add SSL certificate to the ingress
RELEASE_NAME=node-app
# 1.
helm install $RELEASE_NAME ./k8s/helm/app --values ./k8s/helm/values/$ENV/node.yaml
# 2.
helm install $RELEASE_NAME ./ops/k8s/helm/ssl --values ./ops/k8s/helm/values/$ENV/node.yaml
# 3. Change the ingress.tls.enabled to true in values file.
# 4.
helm upgrade $RELEASE_NAME ./ops/k8s/helm/ssl --values ./ops/k8s/helm/values/$ENV/node.yaml
# 5. Keep checking your ingress to see if the certificate is issued. It might take a while.
kubectl get ingress
kubectl describe ingress $INGRESS_NAME
kubectl get certificate
kubectl describe certificate $CERTIFICATE_NAME

# 6. After certificate is issued, run these commands to verify the certificate in Google Cloud
gcloud compute ssl-certificates list
gcloud compute ssl-certificates describe \
  $CERTIFICATE_NAME \
  --format='value(certificate)'

# 7. Enable HTTP to HTTPS redirect: Update ingress.httpsRedirect to true in values file and run the following command
helm upgrade $RELEASE_NAME ./ops/k8s/helm/ssl --values ./ops/k8s/helm/values/$ENV/node.yaml

# To delete the deployment:
helm delete $RELEASE_NAME
```

### Install RabbitMQ and Redis

```bash
## Add the Bitnami repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Deploy rabbitMQ to your node-pool
helm install rabbitmq bitnami/rabbitmq -f ./k8s/helm/values/$ENV/rabbitmq.yaml

# If you face any issue authenticating with RabbitMQ, follow these steps:
kubectl get pods
kubectl exec -it $RABBITMQ_POD_NAME -- bash
rabbitmqctl change_password $USER $PASSWORD


# Deploy redis to your node-pool
helm install redis bitnami/redis -f ./k8s/helm/values/$ENV/redis.yaml
```

## Kubectl Approach

```bash
# You can generate yaml from helm template or create yaml files manually in k8s/manifests folder following the helm template structure
helm template $RELEASE_NAME ./k8s/helm/ --values ./k8s/helm/values/$ENV/$VALUES_FILE_NAME.yaml > k8s/manifests/$RELEASE_NAME.yaml

# Apply k8s yaml files
## Apply the k8s resources individually
kubectl apply -f k8s/manifests/deployment.yaml
kubectl apply -f k8s/manifests/service.yaml
kubectl apply -f k8s/manifests/ingress.yaml
```

### Optional: Add static IP address to the ingress

```bash
    ## Create static IP address
    gcloud compute addresses create $STATIC_IP_NAME --global
    ## Get the static IP address
    gcloud compute addresses describe $STATIC_IP_NAME --global
    ## Add the lines below to the ingress.yaml file
    metadata:
      annotations:
        kubernetes.io/ingress.global-static-ip-name: $STATIC_IP_NAME
    ## Apply modifications to the ingress
    kubectl apply -f k8s/manifests/ingress.yaml
```

### Optional: Add SSL certificate to the ingress using cert-manager and Let's Encrypt [(Guide)]([https://cert-manager.io/docs/tutorials/getting-started-with-cert-manager-on-google-kubernetes-engine-using-lets-encrypt-for-ingress-ssl])

```bash
## Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.2/cert-manager.yaml

## Create Issuer
kubectl apply -f k8s/manifests/issuer.yaml

## Create Secret
kubectl apply -f k8s/manifests/secret.yaml

## Update the lines below in the ingress.yaml file
    metadata:
      annotations:
        cert-manager.io/issuer: $ISSUER_NAME
    spec:
      tls:
      - secretName: $SECRET_NAME
        hosts:
        - $DOMAIN_NAME

## Apply modifications to the ingress
kubectl apply -f k8s/manifests/ingress.yaml

# Get the external IP address of the ingress
kubectl get ingress

# Verify the deployment
curl -v -I http://$DOMAIN_NAME
curl -v -I https://$DOMAIN_NAME

# Enable http to https redirect
kubectl apply -f k8s/manifests/redirect.yaml

# Add the following annotation in ingress
    metadata:
      annotations:
        networking.gke.io/v1beta1.FrontendConfig: $FrontendConfigName #eg. "http-to-https"

# Verify the redirection. curl should return a 301 code
curl -v -I http://$DOMAIN_NAME

# Get the pods information
kubectl get pods

# Get the logs of a pod
kubectl logs -f $POD_NAME
```
