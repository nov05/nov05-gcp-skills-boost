#!/bin/bash
## Created by nov05, 2026-06-11 

# export USER_ID=$(gcloud auth list --format="value(account)" --filter="status:ACTIVE")
export PROJECT_ID=$(gcloud config get-value project)
# export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
#   --format='value(projectNumber)')
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
# export BUCKET="$PROJECT_ID-bucket"
# gcloud config set project $(gcloud projects list --format='value(PROJECT_ID)' --filter='qwiklabs-gcp')
gcloud config set project $PROJECT_ID  
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
echo
echo "🔹  User: $USER"
# echo "🔹  Username: $USER_ID
echo "🔹  Project ID: $PROJECT_ID"
# echo "🔹  Project number: $PROJECT_NUMBER"
echo "🔹  Region: $REGION"
echo "🔹  Zone: $ZONE"
# echo "🔹  Bukect: $BUCKET"
echo
gcloud auth list

cat << 'EOF'

========================================================
Task 1. Create Project 2's virtual machine
========================================================

EOF



cat << 'EOF'

========================================================
Task 2. Monitoring Overview
========================================================

EOF



cat << 'EOF'

========================================================
Task 3. Uptime check for your group
========================================================

EOF



cat << 'EOF'

========================================================
Task 4. Alerting policy for the group
========================================================

EOF



cat << 'EOF'

========================================================
Task 5. Custom dashboard for your group
========================================================

EOF



cat << 'EOF'

========================================================
Task 6. Remove one instance to cause a problem
========================================================

EOF



cat << 'EOF'

========================================================
(Optional) Remove your alerting policy
========================================================

EOF



cat << 'EOF'

========================================================
Task 7. Test your understanding
========================================================

EOF


echo -e "\n✅  All done\n"