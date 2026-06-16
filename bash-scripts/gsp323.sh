#!/bin/bash
## Created by nov05, 2026-06-15  

echo
read -p "👉  Enter BigQuery dataset name (Task 1): " DATASET_NAME
export DATASET_NAME
read -p "👉  Enter cloud storage bucket name (Task 1): " BUCKET
export BUCKET
read -p "👉  Enter BigQuery dataset table name (Task 1): " TABLE_NAME
export TABLE_NAME
read -p "👉  Enter result file name (Task 3): " TASK3_RESULT_FILE
export TASK3_RESULT_FILE
read -p "👉  Enter result file name (Task 4): " TASK4_RESULT_FILE
export TASK4_RESULT_FILE
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
# gcloud auth login --quiet
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
echo "🔹  Bukect: $BUCKET"
echo
gcloud auth list


cat << 'EOF'

========================================================
Task 1. Run a simple Dataflow job
========================================================

(No multiple-choice questions found in this task.)

EOF
## Refer to GSP192

gcloud services disable dataflow.googleapis.com --project $PROJECT_ID --force
gcloud services enable dataflow.googleapis.com --project $PROJECT_ID
until gcloud services list --enabled \
  --project=$PROJECT_ID | grep -q dataflow.googleapis.com
do sleep 5; done

# Create dataset
bq --location=$REGION mk -d $DATASET_NAME

# Create bucket
gcloud storage buckets create gs://$BUCKET \
  --location=$REGION \
  --uniform-bucket-level-access

# Launch Dataflow template job
JOB_NAME=dataflow-$(date +%s)
gcloud dataflow jobs run $JOB_NAME \
  --gcs-location gs://dataflow-templates-us-central1/latest/GCS_Text_to_BigQuery \
  --region=$REGION \
  --parameters \
inputFilePattern=gs://spls/gsp323/lab.csv,\
JSONPath=gs://spls/gsp323/lab.schema,\
outputTable=${PROJECT_ID}:${DATASET_NAME}.${TABLE_NAME},\
bigQueryLoadingTemporaryDirectory=gs://${BUCKET}/bigquery_temp,\
javascriptTextTransformGcsPath=gs://spls/gsp323/lab.js,\
javascriptTextTransformFunctionName=transform \
  --staging-location=gs://${BUCKET}/temp \
  --worker-machine-type=e2-standard-2

echo -e "\n👉  Check BigQuery dataflow job '$JOB_NAME' at"
echo -e "https://console.cloud.google.com/dataflow/jobs?project=${PROJECT_ID}\n"

# watch -n 5 "gcloud dataflow jobs list \
#     --region=$REGION \
#     --format='value(id,name,state)' | grep $JOB_NAME"


cat << 'EOF'

========================================================
Task 2. Run a simple Managed Apache Spark job
========================================================

Note: Before you run your job, log into one of the cluster nodes and copy the `data.txt` file into hdfs using the command
hdfs dfs -cp gs://spls/gsp323/data.txt /data.txt

EOF
## Refer to GSP103

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
  --role="roles/storage.admin"

export CLUSTER_NAME=example-cluster
echo -e "\n👉  Check the cluster '${CLUSTER_NAME}' at"
echo -e "https://console.cloud.google.com/dataproc/clusters?project=${PROJECT_ID}\n"
for i in {1..5}; do
  gcloud dataproc clusters create "$CLUSTER_NAME" \
    --region=$REGION \
    --master-machine-type=n2d-standard-2 \
    --master-boot-disk-type=pd-standard \
    --master-boot-disk-size=100GB \
    --num-workers=2 \
    --worker-machine-type=n2d-standard-2 \
    --worker-boot-disk-type=pd-standard \
    --worker-boot-disk-size=100GB && break
  gcloud dataproc clusters delete "$CLUSTER_NAME" \
    --region=$REGION \
    --quiet
  echo "Retry in 30 seconds"
  sleep 30
done
gcloud dataproc clusters list --region=$REGION
## https://dataproc.googleapis.com/v1/projects/${PROECT_ID}/regions/${REGION}/clusters/${CLUSTER_NAME}
echo -e "\n👉  Check the cluster '${CLUSTER_NAME}' at"
echo -e "https://console.cloud.google.com/dataproc/clusters?project=${PROJECT_ID}\n"

gcloud compute ssh $CLUSTER_NAME-m --zone=$ZONE --quiet
hdfs dfs -cp gs://spls/gsp323/data.txt /data.txt
exit

gcloud dataproc jobs submit spark \
  --cluster=$CLUSTER_NAME \
  --region=$REGION \
  --class=org.apache.spark.examples.SparkPageRank \
  --jars=file:///usr/lib/spark/examples/jars/spark-examples.jar \
  -- /data.txt
echo -e "\n👉  Check the job at"
echo -e "https://console.cloud.google.com/dataproc/jobs??project=${PROJECT_ID}\n"


cat << 'EOF'

========================================================
Task 3. Use the Google Cloud Speech-to-Text API
========================================================

(No multiple-choice questions found in this task.)

EOF
## Refer to GSP119, GSP048

gcloud services disable speech.googleapis.com --project $PROJECT_ID --force
gcloud services enable speech.googleapis.com --project=$PROJECT_ID
until gcloud services list --enabled \
  --project=$PROJECT_ID | grep -q speech.googleapis.com
do sleep 5; done

rm -f request.json result.json
cat > request.json << EOF
{
  "config": {
    "encoding": "FLAC",
    "languageCode": "en-US"
  },
  "audio": {
    "uri": "gs://spls/gsp323/task3.flac"
  }
}
EOF

## ⚠️ Access token doesn't work.
# ## ADC-based
# gcloud auth application-default login --quiet
# gcloud auth application-default set-quota-project $PROJECT_ID
# ## Credentials saved to file: [/tmp/tmp.hMZI46uI8s/application_default_credentials.json]
# ## These credentials will be used by any library that requests Application Default Credentials (ADC).
# export TOKEN=$(gcloud auth application-default print-access-token)
# ## gcloud-based 
# # export TOKEN=$(gcloud auth print-access-token)
# curl -X POST \
#   -H "Content-Type: application/json" \
#   -H "Authorization: Bearer $TOKEN" \
#   "https://speech.googleapis.com/v1/speech:recognize" \
#   -d @request.json > result.json

gcloud services disable apikeys.googleapis.com --project $PROJECT_ID --force
gcloud services enable apikeys.googleapis.com --project $PROJECT_ID
until gcloud services list --enabled \
  --project=$PROJECT_ID | grep -q apikeys.googleapis.com
do sleep 5; done
## Delete multiple API keys by the display name
gcloud alpha services api-keys list \
  --filter="displayName:gsp323-api-key" \
  --format="value(name)" \
| xargs -n 1 -I {} gcloud alpha services api-keys delete "{}"
gcloud alpha services api-keys create \
  --display-name="gsp323-api-key" 
export KEY_ID=$(
  gcloud alpha services api-keys list \
    --format="value(name)" \
    --filter "displayName=gsp323-api-key")
gcloud services api-keys update $KEY_ID \
  --api-target=service=speech.googleapis.com \
  --api-target=service=language.googleapis.com
export API_KEY=$(
  gcloud alpha services api-keys get-key-string $KEY_ID \
    --format="value(keyString)")

curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
"https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" > result.json
echo -e "\n👉  Check the result.\n"
cat result.json
echo
gsutil cp result.json gs://$BUCKET/$TASK3_RESULT_FILE
gsutil setmeta -h "Content-Type:application/json" gs://$BUCKET/$TASK3_RESULT_FILE


cat << 'EOF'

========================================================
Task 4. Use the Cloud Natural Language API
========================================================

(No multiple-choice questions found in this task.)

EOF
## Refer to GSP097

gcloud services disable language.googleapis.com --project $PROJECT_ID --force
gcloud services enable language.googleapis.com --project $PROJECT_ID
until gcloud services list --enabled \
  --project=$PROJECT_ID | grep -q language.googleapis.com
do sleep 5; done

rm -f request.son result.json
cat > request.json <<EOF
{
  "document": {
    "type": "PLAIN_TEXT",
    "content": "Old Norse texts portray Odin as one-eyed and long-bearded, frequently wielding a spear named Gungnir and wearing a cloak and a broad hat."
  },
  "encodingType": "UTF8"
}
EOF

curl -s -X POST \
  -H "Content-Type: application/json" \
  "https://language.googleapis.com/v1/documents:analyzeEntities?key=$API_KEY" \
  -d @request.json > result.json
echo -e "\n👉  Check the result.\n"
cat result.json
echo
gsutil cp result.json gs://$BUCKET/$TASK4_RESULT_FILE
gsutil setmeta -h "Content-Type:application/json" gs://$BUCKET/$TASK4_RESULT_FILE

echo -e "\n✅  All done\n"
