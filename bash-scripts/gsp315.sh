#!/bin/bash
## Created by nov05, 2026-06-10  
## Refer to GSP081, GSP094, GSP095

ask_to_proceed() {
    echo
    while true; do
        read -rp "Ready to proceed? (y): " answer
        [[ "$answer" =~ ^[Yy]$ ]] && break
    done
    echo
    echo
}

echo
read -p "👉  Enter bucket name (Task 1): " BUCKET
export BUCKET 
read -p "👉  Enter topic name (Task 2): " TOPIC
export TOPIC
read -p "👉  Enter Cloud Run function name (Task 3): " FUNCTION
export FUNCTION
read -p "👉  Enter username 2 (Task 4): " USER_ID2
export USER_ID2
echo

export USER_ID=$(gcloud auth list --format="value(account)" --filter="status:ACTIVE")
export PROJECT_ID=$(gcloud config get-value project)
# export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
#   --format='value(projectNumber)')
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
gcloud config set project $PROJECT_ID  
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
echo
echo "🔹  User ID: $USER_ID"
echo "🔹  Project ID: $PROJECT_ID"
# echo "🔹  Project number: $PROJECT_NUMBER"
echo "🔹  Region: $REGION"
echo "🔹  Zone: $ZONE"
echo "🔹  Bukect: $BUCKET"
echo
gcloud auth list

cat << 'EOF'

========================================================
Task 1. Create a bucket
========================================================

EOF

# Create the bucket in the specified region
gsutil mb -l $REGION gs://$BUCKET


cat << 'EOF'

========================================================
Task 2. Create a Pub/Sub topic
========================================================

EOF

gcloud pubsub topics create $TOPIC

cat << 'EOF'

========================================================
Task 3. Create the thumbnail Cloud Run Function
========================================================

EOF

## ⚠️ Unfortunately the function has to be created via console to pass the lab check.
echo -e "\n👉  Create and deploy Cloud Run funcion $FUNCTION at"  
echo -e "https://console.cloud.google.com/run/services?project=$PROJECT_ID\n"
ask_to_proceed

echo -e "\n👉  Test the Cloud Run function...\n"
curl -o map.jpg https://storage.googleapis.com/cloud-training/gsp315/map.jpg
gsutil cp map.jpg gs://$BUCKET/

cat << 'EOF'

========================================================
Task 4. Remove the previous cloud engineer
========================================================

EOF

gcloud projects remove-iam-policy-binding $PROJECT_ID \
  --member="user:$USER_ID2" \
  --role="roles/viewer"


echo -e "\n✅  All done\n"