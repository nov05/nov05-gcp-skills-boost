#!/bin/bash
## Created by nov05, 2026-07-27  

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
Task 1. Understanding Node machine types
========================================================

EOF

cat << 'EOF'

========================================================
Task 2. Choosing the right machine type for the Hello app
========================================================

EOF

# gcloud auth list
gcloud config list project

gcloud container clusters get-credentials hello-demo-cluster --zone $ZONE
kubectl scale deployment hello-server --replicas=2

## 👉 Check my progress

gcloud container clusters resize hello-demo-cluster --node-pool my-node-pool \
  --num-nodes 4 --zone $ZONE --quiet
echo -e "\n👉  Check number of nodes at https://console.cloud.google.com/kubernetes/clusters/details/$ZONE/hello-demo-cluster/nodes?project=$PROJECT_ID\n"

## Migrate to optimized node pool
gcloud container node-pools create larger-pool \
  --cluster=hello-demo-cluster \
  --machine-type=e2-standard-2 \
  --num-nodes=1 \
  --zone=$ZONE

## 👉 Check my progress

## cordon the original node pool
for node in $(kubectl get nodes -l cloud.google.com/gke-nodepool=my-node-pool -o=name); do
  kubectl cordon "$node";
done
## drain the original node pool
for node in $(kubectl get nodes -l cloud.google.com/gke-nodepool=my-node-pool -o=name); do
  kubectl drain --force --ignore-daemonsets --delete-emptydir-data --grace-period=10 "$node";
done
## Verify that the pods are running on the new node pool
kubectl get pods -o=wide

## delete the old node pool
gcloud container node-pools delete my-node-pool --cluster hello-demo-cluster --zone $ZONE --quiet

cat << 'EOF'

========================================================
Task 3. Managing a regional cluster
========================================================

EOF

gcloud container clusters create regional-demo --region=$REGION --num-nodes=1

## create a manifest for your first pod
cat << EOF > pod-1.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-1
  labels:
    security: demo
spec:
  containers:
  - name: container-1
    image: wbitt/network-multitool
EOF
kubectl apply -f pod-1.yaml

## create a manifest for your second pod
cat << EOF > pod-2.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-2
spec:
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: security
            operator: In
            values:
            - demo
        topologyKey: "kubernetes.io/hostname"
  containers:
  - name: container-2
    image: us-docker.pkg.dev/google-samples/containers/gke/hello-app:1.0
EOF
kubectl apply -f pod-2.yaml

## 👉 Check my progress

## View the pods you created
kubectl get pod pod-1 pod-2 --output wide

## Simulate cross-zonal traffic by pinging pod-2 from pod-1
# POD2_IP=$(kubectl get pod pod-2 -o jsonpath='{.status.podIP}')
# ## Get a shell to your pod-1 container
# kubectl exec -it pod-1 -- sh
# ping $POD2_IP
# ## Ctrl+C to stop pinging and exit the shell
# exit
kubectl exec pod-1 -- sh -c "ping -c 100 $(kubectl get pod pod-2 -o jsonpath='{.status.podIP}')"

## 👉 Manually complete the task

## Move a chatty pod to minimize cross-zonal traffic costs
## changes your Pod Anti Affinity rule into a Pod Affinity
sed -i 's/podAntiAffinity/podAffinity/g' pod-2.yaml
kubectl delete pod pod-2
kubectl create -f pod-2.yaml
kubectl get pod pod-1 pod-2 --output wide

# kubectl exec -it pod-1 -- sh
# ping $POD2_IP
# ## Ctrl+C to stop pinging and exit the shell
# exit
kubectl exec pod-1 -- sh -c "ping -c 100 $(kubectl get pod pod-2 -o jsonpath='{.status.podIP}')"

## 👉 Check my progress

echo -e "\n✅  All done\n"