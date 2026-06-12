#!/bin/bash
## Created by nov05, 2026-06-11  

export USER_ID=$(gcloud auth list --format="value(account)" --filter="status:ACTIVE")
export PROJECT_ID=$(gcloud config get-value project)
# export PROJECT_ID=$(gcloud projects list --format='value(PROJECT_ID)' \
#   --filter='qwiklabs-gcp')
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
  --format='value(projectNumber)')
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
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
# echo "🔹  Bukect: $BUCKET"
echo
gcloud auth list

cat << 'EOF'

========================================================
Task 1. Viewing Cloud Run function logs & metrics in Cloud Monitoring
========================================================

EOF
## Refer to GSP081, GSP315 for Cloud Run function creation
echo -e "\n👉  Enabling services...\n"
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com 
  # cloudfunctions.googleapis.com \
  # eventarc.googleapis.com
# until enabled=$(gcloud services list --enabled --project=$PROJECT_ID); \
#   echo "$enabled" | grep -q run.googleapis.com && \
#   echo "$enabled" | grep -q artifactregistry.googleapis.com && \
#   echo "$enabled" | grep -q cloudbuild.googleapis.com && \
#   echo "$enabled" | grep -q cloudfunctions.googleapis.com \
#   echo "$enabled" | grep -q eventarc.googleapis.com
# do sleep 5; done

mkdir myfunc && cd myfunc
cat > index.js << 'EOF'
const functions = require('@google-cloud/functions-framework');
functions.http('helloHttp', (req, res) => {
  res.set('Content-Type', 'text/plain');
  res.send(`Hello ${req.query.name || req.body.name || 'World'}!`);
});
EOF
cat > package.json << 'EOF'
{
  "dependencies": {
    "@google-cloud/functions-framework": "^3.0.0"
  }
}
EOF
cd ..
echo -e "\n👉  Deploying Cloud Run function 'helloworld'...\n"
## ⚠️ It may need retry a couple of times.
for i in {1..10}; do
  gcloud functions deploy helloworld \
    --gen2 \
    --runtime=nodejs22 \
    --region=$REGION \
    --source=./myfunc \
    --entry-point=helloHttp \
    --trigger-http \
    --allow-unauthenticated \
    --max-instances=5 \
    --timeout=300 \
    --memory=512Mi \
    --cpu=1 \
    --concurrency=80 && break
  echo "Retry in 30 seconds..."
  sleep 30
done
## https://docs.cloud.google.com/run/docs/configuring/execution-environments
gcloud run services update helloworld \
  --region=$REGION \
  --execution-environment gen2

## Re-deploy the function via console to pass the lab check.
echo -e "\n👉  Check Cloud Run funcion 'helloworld' at"  
echo -e "https://console.cloud.google.com/run/detail/${REGION}/helloworld/source?project=$PROJECT_ID"

## Get a tool called vegeta that will let you send some test traffic to your Cloud Run function
curl -LO 'https://github.com/tsenart/vegeta/releases/download/v12.12.0/vegeta_12.12.0_linux_386.tar.gz'
tar -xvzf vegeta_12.12.0_linux_386.tar.gz
CLOUD_RUN_URL=$(gcloud run services describe helloworld --region=$REGION --format='value(status.url)')
echo -e "\n👉  Cloud Run function url: $CLOUD_RUN_URL\n"
echo "GET $CLOUD_RUN_URL" | ./vegeta attack -duration=300s -rate=200 > results.bin &
echo "GET $CLOUD_RUN_URL" | ./vegeta attack -duration=300s -rate=200 > results.bin &


cat << 'EOF'

========================================================
Task 2. Create a logs-based metric
========================================================

EOF
## Refer to GSP091, Task 5

cat > metric.yaml <<'EOF'
name: CloudRunFunctionLatency-Logs
description: Cloud Run function latency distribution
filter: |
  resource.type="cloud_run_revision"
  resource.labels.service_name="helloworld"
valueExtractor: EXTRACT(httpRequest.latency)
bucketOptions:
  explicitBuckets:
    bounds:
      - 0
      - 0.1
      - 0.25
      - 0.5
      - 1
      - 2
      - 5
      - 10
metricDescriptor:
  metricKind: DELTA
  valueType: DISTRIBUTION
  unit: "1"
EOF
gcloud logging metrics create CloudRunFunctionLatency-Logs \
  --config-from-file="metric.yaml"

# gcloud logging metrics delete CloudRunFunctionLatency-Logs --quiet

cat << 'EOF'

========================================================
Task 3. Metrics Explorer
========================================================

EOF

echo -e "\n👉  Check the logs at"
echo "https://console.cloud.google.com/logs/query?project=${PROJECT_ID}"
echo -e "\n👉  Check the metric at"
echo -e "https://console.cloud.google.com/monitoring/metrics-explorer?project=$PROJECT_ID\n"

cat << 'EOF'

========================================================
Task 4. Create charts on the Monitoring Overview window
========================================================

EOF

curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/dev/files/gsp092/GSP092%20Dashboard%20-%20Jun%2012%2C%202026%205_25%20AM.json
gcloud monitoring dashboards create \
  --config-from-file="GSP092 Dashboard - Jun 12, 2026 5_25 AM.json"

cat << 'EOF'

========================================================
Task 5. Test your understanding
========================================================

1. List out two types of log-based metrics.
  System logs-based metrics
  User-defined logs-based metrics

2. Vegeta is a versatile HTTP load testing tool built out of a need to drill HTTP 
  services with a constant request rate.
  True
EOF


echo -e "\n✅  All done\n"