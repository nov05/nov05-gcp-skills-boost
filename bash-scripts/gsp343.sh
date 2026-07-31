#!/bin/bash
## Created by nov05, 2026-07-30  

export USER_ID=$(gcloud auth list --format="value(account)" --filter="status:ACTIVE")
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
  --format='value(projectNumber)')
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
# export ZONE2=$(gcloud compute zones list \
#   --filter="region:$REGION" \
#   --format="value(name)" | grep -v $ZONE | head -n 1)
# export BUCKET="$PROJECT_ID-bucket"
gcloud config set account $USER_ID
gcloud config set project $PROJECT_ID  
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
echo
echo "🔹  User: $USER"
echo "🔹  Username: $USER_ID"
echo "🔹  Project ID: $PROJECT_ID"
echo "🔹  Project number: $PROJECT_NUMBER"
echo "🔹  Region: $REGION"
echo "🔹  Zone: $ZONE"
# echo "🔹  Zone 2: $ZONE2"
# echo "🔹  Bukect: $BUCKET"
echo
gcloud auth list




cat << 'EOF'

========================================================
Task 1. Create a cluster and deploy your app
========================================================

EOF

# Create the GKE cluster
gcloud container clusters create $CLUSTER \
    --zone=$ZONE \
    --num-nodes=2 \
    --machine-type=e2-standard-2 \
    --release-channel=rapid
# Configure kubectl to use the cluster
gcloud container clusters get-credentials $CLUSTER --zone=$ZONE

# Create the namespaces
kubectl create namespace dev
kubectl create namespace prod

# Deploy the application to the dev namespace
kubectl apply -f ./release/kubernetes-manifests.yaml --namespace=dev

git clone https://github.com/GoogleCloudPlatform/microservices-demo.git &&
cd microservices-demo && kubectl apply -f ./release/kubernetes-manifests.yaml --namespace dev

## 👉 Check my progress



cat << 'EOF'

========================================================
Task 2. Migrate to an optimized node pool
========================================================

EOF

# Create the new optimized node pool
gcloud container node-pools create $NODE_POOL \
  --cluster=$CLUSTER \
  --zone=$ZONE \
  --machine-type=custom-2-3584 \
  --num-nodes=2

# Get the names of the default-pool nodes
DEFAULT_POOL_NODES=$(kubectl get nodes -o name | grep default-pool)
# Cordon all default-pool nodes
for node in $DEFAULT_POOL_NODES; do
  kubectl cordon "${node#node/}"
done
# Drain the old nodes
for node in $DEFAULT_POOL_NODES; do
  kubectl drain "${node#node/}" --ignore-daemonsets --delete-emptydir-data
done
# Verify workloads have migrated
kubectl get pods -n dev -o wide

# Delete the old node pool
gcloud container node-pools delete default-pool \
  --cluster=$CLUSTER \
  --zone=$ZONE

## 👉 Check my progress




cat << 'EOF'

========================================================
Task 3. Apply a frontend update
========================================================

EOF

# Create a Pod Disruption Budget
kubectl create pdb onlineboutique-frontend-pdb \
  --selector=app=frontend \
  --min-available=1 \
  -n dev

CONTAINER=$(kubectl get deployment frontend -n dev -o jsonpath='{.spec.template.spec.containers[*].name}')

# Update the frontend image
kubectl set image deployment/frontend \
  $CONTAINER=gcr.io/qwiklabs-resources/onlineboutique-frontend:v2.1 \
  -n dev

# Set ImagePullPolicy to Always
kubectl patch deployment frontend -n dev \
  --type='strategic' \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"'$CONTAINER'","imagePullPolicy":"Always"}]}}}}'

# Verify
kubectl get pdb -n dev
kubectl rollout status deployment/frontend -n dev




cat << 'EOF'

========================================================
Task 4. Autoscale from estimated traffic
========================================================

EOF

# Apply HPA to the frontend deployment
kubectl autoscale deployment frontend \
    --cpu-percent=50 \
    --min=1 \
    --max=<Max Replicas> \
    -n dev

# Enable cluster autoscaling on the node pool
gcloud container clusters update $CLUSTER \
    --zone=$ZONE \
    --enable-autoscaling \
    --node-pool=$NODE_POOL \
    --min-nodes=1 \
    --max-nodes=6

## 👉 Check my progress

# Get the frontend external IP
FRONTEND_IP=$(kubectl get svc frontend-external -n dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
# Run the load test
kubectl exec $(kubectl get pod --namespace=dev | grep 'loadgenerator' | cut -f1 -d ' ') \
    -it --namespace=dev -- \                              
    sh -c "export USERS=8000; locust --host=\"http://$FRONTEND_IP\" --headless -u 8000 2>&1"

# Apply HPA to the recommendationservice deployment
kubectl autoscale deployment recommendationservice \
    --cpu-percent=50 \
    --min=1 \
    --max=5 \
    -n dev

# Verify
kubectl get hpa -n dev
kubectl get nodes
kubectl get pods -n dev




cat << 'EOF'

========================================================
Task 5. (Optional) Optimize other services
========================================================

EOF

# Check Horizontal Pod Autoscalers
kubectl get hpa -n dev

# Check pods and resource usage
kubectl get pods -n dev
kubectl top pods -n dev
kubectl top nodes

# Inspect deployments
kubectl get deployments -n dev
kubectl describe deployment <DEPLOYMENT_NAME> -n dev

# (Optional) Apply HPA to another deployment
kubectl autoscale deployment <DEPLOYMENT_NAME> \
    --cpu-percent=50 \
    --min=1 \
    --max=5 \
    -n dev
    



echo -e "\n✅  All done\n"