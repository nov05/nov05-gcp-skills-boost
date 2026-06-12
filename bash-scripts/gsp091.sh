#!/bin/bash
## Created by nov05, 2026-06-11 

export USER_ID=$(gcloud auth list --format="value(account)" --filter="status:ACTIVE")
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
  --format='value(projectNumber)')
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
# export BUCKET="$PROJECT_ID-bucket"
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
# echo "🔹  Bukect: $BUCKET"
echo
gcloud auth list

cat << 'EOF'

========================================================
Task 1. Deploy a GKE cluster
========================================================

EOF

gcloud container clusters create gmp-cluster --num-nodes=1 --zone $ZONE
cat << 'EOF'

👉  Note: It may take several minutes for the cluster to be deployed. You can 
  proceed to complete Task 2, and then return to validate your progress in the lab.
EOF

cat << 'EOF'

========================================================
Task 2. Create a log-based alert
========================================================

EOF

## Create an email notification channel
cat << EOF > email-channel.json
{
  "type": "email",
  "displayName": "$USER_ID",
  "labels": {
    "email_address": "$USER_ID"
  }
}
EOF
gcloud alpha monitoring channels create \
  --channel-content-from-file=email-channel.json
CHANNEL_ID=$(
  gcloud alpha monitoring channels list \
    --filter="displayName=\"$USER_ID\"" \
    --format="value(name)" \
    --limit=1
)

cat << EOF > stopped-vm-alert.json
{
  "displayName": "stopped vm",
  "combiner": "OR",
  "conditions": [
    {
      "displayName": "VM stop detected",
      "conditionMatchedLog": {
        "filter": "resource.type=\"gce_instance\" protoPayload.methodName=\"v1.compute.instances.stop\""
      }
    }
  ],
  "alertStrategy": {
    "notificationRateLimit": {
      "period": "300s"
    },
    "autoClose": "3600s"
  },
  "notificationChannels": [
    "${CHANNEL_ID}"
  ],
  "enabled": true
}
EOF
gcloud alpha monitoring policies create \
  --policy-from-file=stopped-vm-alert.json

echo -e "\n👉  Test the log-based alert...\n"
gcloud compute instances stop instance1 --zone $ZONE


cat << 'EOF'

========================================================
Task 3. Create a Docker repository
========================================================

EOF

gcloud artifacts repositories create docker-repo --repository-format=docker \
    --location=$REGION --description="Docker repository" \
    --project=$PROJECT_ID

## Load a pre-built image from a storage bucket
wget https://storage.googleapis.com/spls/gsp1024/flask_telemetry.zip
unzip flask_telemetry.zip
docker load -i flask_telemetry.tar

docker tag gcr.io/ops-demo-330920/flask_telemetry:61a2a7aabc7077ef474eb24f4b69faeab47deed9 \
  $REGION-docker.pkg.dev/$PROJECT_ID/docker-repo/flask-telemetry:v1
docker push $REGION-docker.pkg.dev/$PROJECT_ID/docker-repo/flask-telemetry:v1


cat << 'EOF'

========================================================
Task 4. Deploy a simple application that emits metrics
========================================================

EOF

# gcloud container clusters list
until [ "$(gcloud container clusters describe gmp-cluster --format='value(status)')" = "RUNNING" ]; do
  sleep 10
done
echo "👉  Cluster 'gmp-cluster' is fully provisioned."

## Create a namespace
gcloud container clusters get-credentials gmp-cluster
kubectl create ns gmp-test

## Get the application which emits metrics at the /metrics endpoint
wget https://storage.googleapis.com/spls/gsp1024/gmp_prom_setup.zip
unzip gmp_prom_setup.zip
cd gmp_prom_setup

## Add the name of the image pushed in previous steps
# nano flask_deployment.yaml
sed -i "s|<ARTIFACT REGISTRY IMAGE NAME>|${REGION}-docker.pkg.dev/${PROJECT_ID}/docker-repo/flask-telemetry:v1|g" \
  flask_deployment.yaml

## Deploy a simple application that emits metrics at the /metrics endpoint
kubectl -n gmp-test apply -f flask_deployment.yaml
kubectl -n gmp-test apply -f flask_service.yaml

## Verify that the namespace is ready and emitting metrics
# kubectl get services -n gmp-test
until kubectl get services -n gmp-test \
  -o jsonpath='{.items[*].status.loadBalancer.ingress[0].ip}' | grep -qv "<pending>"; do
  sleep 10
done
echo -e "\n👉  External-IP is now available."
kubectl get services -n gmp-test

## Check that the Python Flask app is serving metrics
curl $(kubectl get services \
  -n gmp-test \
  -o jsonpath='{.items[*].status.loadBalancer.ingress[0].ip}')/metrics


cat << 'EOF'

========================================================
Task 5. Create a log-based metric
========================================================

EOF

gcloud logging metrics create hello-app-error \
  --description="Count hello-app 404 errors" \
  --log-filter='
severity=ERROR
resource.labels.container_name="hello-app"
textPayload:"ERROR: 404 Error page not found"
'

cat << 'EOF'

========================================================
Task 6. Create a metrics-based alert
========================================================

EOF

# gcloud logging metrics list

gcloud alpha monitoring policies create --policy-from-file=- << EOF
displayName: log based metric alert
combiner: OR
enabled: true
conditions:
  - displayName: hello-app-error condition
    conditionThreshold:
      filter: 'resource.type="global" AND metric.type="logging.googleapis.com/user/hello-app-error"'
      comparison: COMPARISON_GT
      thresholdValue: 0
      duration: 120s
      trigger:
        count: 1
EOF

cat << 'EOF'

========================================================
Task 7. Generate some errors
========================================================

EOF

timeout 130 bash -c -- '
while true; do
  curl $(kubectl get services -n gmp-test -o jsonpath="{.items[*].status.loadBalancer.ingress[0].ip}")/error
  sleep $((RANDOM % 4))
done
'

echo -e "\n✅  All done\n"