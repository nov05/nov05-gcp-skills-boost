#!/bin/bash
## Created by nov05, 2026-07-24  

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
Task 1. Download required files
========================================================

EOF

gsutil -m cp -r gs://spls/gsp766/gke-qwiklab ~
cd ~/gke-qwiklab


cat << 'EOF'

========================================================
Task 2. View and create namespaces
========================================================

EOF

gcloud config set compute/zone ${ZONE} && gcloud container clusters get-credentials multi-tenant-cluster

kubectl get namespace

kubectl api-resources --namespaced=true

kubectl get services --namespace=kube-system

kubectl create namespace team-a && \
kubectl create namespace team-b

kubectl run app-server --image=quay.io/centos/centos:9 --namespace=team-a -- sleep infinity && \
kubectl run app-server --image=quay.io/centos/centos:9 --namespace=team-b -- sleep infinity

kubectl get pods -A

kubectl describe pod app-server --namespace=team-a

kubectl config set-context --current --namespace=team-a

kubectl describe pod app-server


cat << 'EOF'

========================================================
Task 3. Access Control in namespaces
========================================================

EOF

gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
  --member=serviceAccount:team-a-dev@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com  \
  --role=roles/container.clusterViewer

kubectl create role pod-reader \
  --resource=pods --verb=watch --verb=get --verb=list

cat developer-role.yaml
kubectl create -f developer-role.yaml
kubectl create rolebinding team-a-developers \
  --role=developer --user=team-a-dev@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com
gcloud iam service-accounts keys create /tmp/key.json --iam-account team-a-dev@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com

gcloud auth activate-service-account  --key-file=/tmp/key.json

gcloud container clusters get-credentials multi-tenant-cluster --zone ${ZONE} --project ${GOOGLE_CLOUD_PROJECT}

kubectl get pods --namespace=team-a

kubectl get pods --namespace=team-b

gcloud config set account student-04-4af39c759efa@qwiklabs.net
gcloud container clusters get-credentials multi-tenant-cluster --zone ${ZONE} --project ${GOOGLE_CLOUD_PROJECT}

cat << 'EOF'

========================================================
Task 4. Resource quotas
========================================================

EOF

kubectl create quota test-quota \
  --hard=count/pods=2,count/services.loadbalancers=1 --namespace=team-a
kubectl run app-server-2 --image=quay.io/centos/centos:9 --namespace=team-a -- sleep infinity
kubectl run app-server-3 --image=quay.io/centos/centos:9 --namespace=team-a -- sleep infinity
kubectl describe quota test-quota --namespace=team-a

export KUBE_EDITOR="nano"
kubectl edit quota test-quota --namespace=team-a
kubectl describe quota test-quota --namespace=team-a

kubectl create -f cpu-mem-quota.yaml
kubectl create -f cpu-mem-demo-pod.yaml --namespace=team-a
kubectl describe quota cpu-mem-quota --namespace=team-a


cat << 'EOF'

========================================================
Task 5. Monitoring GKE and GKE usage metering
========================================================

EOF

gcloud container clusters \
  update multi-tenant-cluster --zone ${ZONE} \
  --resource-usage-bigquery-dataset cluster_dataset

export GCP_BILLING_EXPORT_TABLE_FULL_PATH=${GOOGLE_CLOUD_PROJECT}.billing_dataset.gcp_billing_export_v1_xxxx
export USAGE_METERING_DATASET_ID=cluster_dataset
export COST_BREAKDOWN_TABLE_ID=usage_metering_cost_breakdown
export USAGE_METERING_QUERY_TEMPLATE=~/gke-qwiklab/usage_metering_query_template.sql
export USAGE_METERING_QUERY=cost_breakdown_query.sql
export USAGE_METERING_START_DATE=2020-10-26
sed \
-e "s/\${fullGCPBillingExportTableID}/$GCP_BILLING_EXPORT_TABLE_FULL_PATH/" \
-e "s/\${projectID}/$GOOGLE_CLOUD_PROJECT/" \
-e "s/\${datasetID}/$USAGE_METERING_DATASET_ID/" \
-e "s/\${startDate}/$USAGE_METERING_START_DATE/" \
"$USAGE_METERING_QUERY_TEMPLATE" \
> "$USAGE_METERING_QUERY"

bq query \
--project_id=$GOOGLE_CLOUD_PROJECT \
--use_legacy_sql=false \
--destination_table=$USAGE_METERING_DATASET_ID.$COST_BREAKDOWN_TABLE_ID \
--schedule='every 24 hours' \
--display_name="GKE Usage Metering Cost Breakdown Scheduled Query" \
--replace=true \
"$(cat $USAGE_METERING_QUERY)"

echo -e "\n✅  All done\n"