#!/bin/bash
## Created by nov05, 2026-05-11  

# cat >> ~/.bashrc <<'EOF'
## Get project id, project number, region, zone
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
  --format='value(projectNumber)')
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
# export USER_EMAIL=$(gcloud auth list --format="value(account)" --filter="status:ACTIVE")
# export BUCKET="$PROJECT_ID-bucket"
# gcloud config set project $(gcloud projects list --format='value(PROJECT_ID)' --filter='qwiklabs-gcp')
gcloud config set project $PROJECT_ID  
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
echo
echo "🔹  User: $USER"
# echo "🔹  User email: $USER_EMAIL"
echo "🔹  Project ID: $PROJECT_ID"
# echo "🔹  Project number: $PROJECT_NUMBER"
echo "🔹  Region: $REGION"
echo "🔹  Zone: $ZONE"
# echo "🔹  Bukect: $BUCKET"
echo
# EOF
# source ~/.bashrc
gcloud auth list

cat << 'EOF'

========================================================
Task 1. ...
========================================================

EOF

cat << 'EOF'

========================================================
Task 2. ...
========================================================

EOF

echo -e "\n✅  All done\n"
