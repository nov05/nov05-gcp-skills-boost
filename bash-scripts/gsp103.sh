#!/bin/bash
## Created by nov05, 2026-06-14  

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
Task 1. Create a cluster
========================================================

(There are no multiple-choice questions in this task.)

EOF

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
    --role="roles/storage.admin"

export CLUSTER_NAME=example-cluster
for i in {1..5}; do
    gcloud dataproc clusters create "$CLUSTER_NAME" \
        --region=$REGION \
        --zone=$ZONE \
        --master-machine-type=e2-standard-2 \
        --master-boot-disk-type=pd-standard \
        --master-boot-disk-size=30GB \
        --num-workers=2 \
        --worker-machine-type=e2-standard-2 \
        --worker-boot-disk-type=pd-standard \
        --worker-boot-disk-size=30GB && break
    gcloud dataproc clusters delete "$CLUSTER_NAME" \
        --region=us-west4 \
        --quiet
    echo "Retry in 30 seconds"
    sleep 30
done
echo -e "\n👉  Check the cluster '${CLUSTER_NAME}' at"
echo -e "https://console.cloud.google.com/dataproc/clusters?project=${PROJECT_ID}\n"


cat << 'EOF'

========================================================
Task 2. Submit a job
========================================================

(There are no multiple-choice questions in this task.)
(There is no Bash code from the lab.)

EOF

gcloud dataproc jobs submit spark \
    --cluster="$CLUSTER_NAME" \
    --region=$REGION \
    --class=org.apache.spark.examples.SparkPi \
    --jars=file:///usr/lib/spark/examples/jars/spark-examples.jar \
    -- 1000


cat << 'EOF'

========================================================
Task 3. View the job output
========================================================

(There are no multiple-choice questions in this task.)

EOF

echo -e "\n👉  Check the job at"
echo -e "https://console.cloud.google.com/dataproc/jobs??project=${PROJECT_ID}\n"


cat << 'EOF'

========================================================
Task 4. Update a cluster to modify the number of workers
========================================================

(There are no multiple-choice questions in this task.)

EOF

## Resize the cluster from 2 workers to 4 workers
gcloud dataproc clusters update "$CLUSTER_NAME" \
    --region="$REGION" \
    --num-workers=4

## Optional: verify the new worker count
gcloud dataproc clusters describe "$CLUSTER_NAME" \
    --region="$REGION"

cat << 'EOF'

========================================================
Task 5. Test your understanding
========================================================

Question 1: Which type of Managed Apache Spark job is submitted in the lab?
Answer: Spark

Question 2: Managed Apache Spark helps users process, transform and understand vast quantities of data.
Answer: True

EOF

echo -e "\n✅  All done\n"