#!/bin/bash
## Created by nov05, 2026-06-12
## Refer to GSP081, GSP315, GSP090, GSP091, GSP092  

echo
## export METRIC_NAME=large_video_upload_rate
read -p "👉  Enter metric name (Task 3): " METRIC_NAME
export METRIC_NAME
read -p "👉  Enter alert shreshold (Task 5): " ALERT_SHRESHOLD
export ALERT_SHRESHOLD
echo

export USER_ID=$(gcloud auth list --format="value(account)" --filter="status:ACTIVE")
export PROJECT_ID=$(gcloud config get-value project)
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
Task 1. Configure Cloud Monitoring
========================================================

EOF

gcloud services enable \
  monitoring.googleapis.com \
  logging.googleapis.com
echo -e "\n👉  Check the dashboard at"  
echo -e "https://console.cloud.google.com/monitoring/dashboards?project=${PROJECT_ID}\n"


cat << 'EOF'

========================================================
Task 2. Configure a Compute Instance to generate Custom Cloud Monitoring metrics
========================================================

EOF

# gcloud compute ssh video-queue-monitor --zone=$ZONE

cat > startup.sh << 'EOF'
#!/bin/bash

export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export INSTANCE_ID=$(gcloud compute instances describe video-queue-monitor \
  --zone=$ZONE \
  --format="value(id)")

## Install Golang
sudo apt update && sudo apt -y
sudo apt-get install wget -y
sudo apt-get -y install git
sudo chmod 777 /usr/local/
sudo wget https://go.dev/dl/go1.23.0.linux-amd64.tar.gz 
sudo tar -C /usr/local -xzf go1.23.0.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Install ops agent 
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
sudo service google-cloud-ops-agent start

# Create go working directory and add go path
mkdir /work
mkdir /work/go
mkdir /work/go/cache
export GOPATH=/work/go
export GOCACHE=/work/go/cache

# Install Video queue Go source code
cd /work/go
mkdir video
gsutil cp gs://spls/gsp338/video_queue/main.go /work/go/video/main.go

# Get Cloud Monitoring (stackdriver) modules
go get go.opencensus.io
go get contrib.go.opencensus.io/exporter/stackdriver

# Configure env vars for the Video Queue processing application
export MY_PROJECT_ID=$PROJECT_ID
export MY_GCE_INSTANCE_ID=$INSTANCE_ID
export MY_GCE_INSTANCE_ZONE=$ZONE

# Initialize and run the Go application
cd /work
go mod init go/video/main
go mod tidy
go run /work/go/video/main.go
EOF
export VM_NAME="video-queue-monitor"
gcloud compute instances add-metadata $VM_NAME \
  --zone=$ZONE \
  --metadata-from-file startup-script=startup.sh
gcloud compute instances reset video-queue-monitor --zone=$ZONE

curl -s -H "Authorization: Bearer $(gcloud auth print-access-token)" \
"https://monitoring.googleapis.com/v3/projects/$PROJECT_ID/metricDescriptors" \
| jq '.metricDescriptors[]?.type' | grep input_queue_size

echo -e "\n👉  Check the metric 'input_queue_size' at"  
echo -e "https://console.cloud.google.com/monitoring/metrics-explorer?project=${PROJECT_ID}\n"  


cat << 'EOF'

========================================================
Task 3. Create a custom metric using Cloud Operations logging events
========================================================

EOF

cat > metric.yaml << EOF
name: $METRIC_NAME
description: Tracks rate of 4K and 8K video uploads
filter: |
  textPayload=~"file_format: (4K|8K)"
metricDescriptor:
  metricKind: DELTA
  valueType: INT64
  unit: "1"
EOF
gcloud logging metrics create "$METRIC_NAME" \
  --config-from-file="metric.yaml"

echo -e "\n👉  Check the metric '${METRIC_NAME}' at"  
echo -e "https://console.cloud.google.com/monitoring/metrics-explorer?project=${PROJECT_ID}\n"  


cat << 'EOF'

========================================================
Task 4. Add custom metrics to the Media Dashboard in Cloud Operations Monitoring
========================================================

EOF

curl -o "Media_Dashboard.json" \
  -L https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/dev/files/gsp338/Media_Dashboard.json
gcloud monitoring dashboards create \
  --config-from-file="Media_Dashboard.json"
echo -e "\n👉  Check the dashboard at"
echo -e "https://console.cloud.google.com/monitoring/dashboards?project=${PROJECT_ID}\n"


cat << 'EOF'

========================================================
Task 5. Create a Cloud Operations alert based on the rate of high resolution video file uploads
========================================================

EOF

cat > alert-policy.json <<EOF
{
  "displayName": "High Resolution Video Upload Alert",
  "combiner": "OR",
  "enabled": true,
  "conditions": [
    {
      "displayName": "4K/8K upload rate condition",
      "conditionThreshold": {
        "filter": "resource.type=\"global\" AND metric.type=\"logging.googleapis.com/user/$METRIC_NAME\"",
        "comparison": "COMPARISON_GT",
        "thresholdValue": $ALERT_SHRESHOLD,
        "duration": "60s",
        "aggregations": [
          {
            "alignmentPeriod": "60s",
            "perSeriesAligner": "ALIGN_RATE",
            "crossSeriesReducer": "REDUCE_SUM",
            "groupByFields": []
          }
        ]
      }
    }
  ],
  "notificationChannels": []
}
EOF
gcloud alpha monitoring policies create \
  --project="$PROJECT_ID" \
  --policy-from-file="alert-policy.json"

echo -e "\n👉  Check the alert policy 'High Resolution Video Upload Alert' at"  
echo -e "https://console.cloud.google.com/monitoring/alerting?project=${PROJECT_ID}\n" 


echo -e "\n✅  All done\n"