#!/bin/bash
## Created by nov05, 2026-07-04  

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
Task 1. Create a continuous export pipeline to Pub/Sub
========================================================

EOF

gcloud services enable securitycenter.googleapis.com
until gcloud services list --enabled \
  --project=$PROJECT_ID | grep -q securitycenter.googleapis.com
do sleep 5; done

gcloud pubsub topics create export-findings-pubsub-topic

## Debug: Add argument --log-http to the command below to see the HTTP request and response
gcloud scc notifications create export-findings-pubsub \
  --project=$PROJECT_ID \
  --description="Continuous exports of Findings to Pub/Sub and BigQuery" \
  --pubsub-topic=projects/$PROJECT_ID/topics/export-findings-pubsub-topic \
  --filter='state="ACTIVE" AND NOT mute="MUTED"'

gcloud pubsub subscriptions create export-findings-pubsub-topic-sub \
  --project=$PROJECT_ID \
  --topic=export-findings-pubsub-topic

gcloud compute instances create instance-1 --zone=$ZONE \
  --machine-type e2-micro \
  --scopes=https://www.googleapis.com/auth/cloud-platform
until gcloud compute ssh instance-1 \
    --zone=$ZONE \
    --command="echo Instance is ready." \
    --quiet 2>/dev/null
do sleep 5; done

gcloud compute instances create instance-2 --zone=$ZONE \
  --machine-type e2-micro \
  --scopes=https://www.googleapis.com/auth/cloud-platform
until gcloud compute ssh instance-2 \
    --zone=$ZONE \
    --command="echo Instance is ready." \
    --quiet 2>/dev/null
do sleep 5; done

gcloud pubsub subscriptions pull export-findings-pubsub-topic-sub \
  --project=$PROJECT_ID \
  --auto-ack


cat << 'EOF'

========================================================
Task 2. Export and analyze SCC findings with BigQuery
========================================================

EOF

bq --location=$REGION --apilog=/dev/null mk --dataset \
  $PROJECT_ID:continuous_export_dataset

gcloud scc bqexports create scc-bq-cont-export \
  --project=$PROJECT_ID \
  --dataset=projects/$PROJECT_ID/datasets/continuous_export_dataset 

bq ls continuous_export_dataset
until bq ls continuous_export_dataset 2>/dev/null | grep -q .; do
  sleep 5
done
echo "Dataset is available."

for i in {0..2}; do
  gcloud iam service-accounts create sccp-test-sa-$i;
  gcloud iam service-accounts keys create /tmp/sa-key-$i.json \
    --iam-account=sccp-test-sa-$i@"$PROJECT_ID".iam.gserviceaccount.com;
done
for i in {0..2}; do
  until gcloud iam service-accounts describe \
    "sccp-test-sa-$i@$PROJECT_ID.iam.gserviceaccount.com" >/dev/null 2>&1
  do sleep 5; done
done
## Confirm all the keys have been created.
ls -la /tmp/sa-key-*.json

bq query --apilog=/dev/null --use_legacy_sql=false  \
  "SELECT finding_id,event_time,finding.category FROM continuous_export_dataset.findings"

gcloud storage buckets create gs://scc-export-bucket-$PROJECT_ID \
  --location=$REGION \
  --public-access-prevention
# gcloud storage rm --recursive gs://scc-export-bucket-$PROJECT_ID

gcloud scc findings list projects/$PROJECT_ID --format=json > findings.json
jq -c '.[]' findings.json > findings.jsonl
gcloud storage cp findings.jsonl gs://scc-export-bucket-$PROJECT_ID/findings.jsonl

## ⚠️ This might not pass the lab check. Then you will have to create the table manually in the BigQuery console.
bq mk --table \
  --schema='resource:JSON,finding:JSON' \
  $PROJECT_ID:continuous_export_dataset.old_findings
bq load \
  --source_format=NEWLINE_DELIMITED_JSON \
  $PROJECT_ID:continuous_export_dataset.old_findings \
  gs://scc-export-bucket-$PROJECT_ID/findings.jsonl
bq show $PROJECT_ID:continuous_export_dataset.old_findings
bq query --use_legacy_sql=false \
  "SELECT * FROM \`$PROJECT_ID.continuous_export_dataset.old_findings\` LIMIT 10"

echo -e "\n✅  All done\n"