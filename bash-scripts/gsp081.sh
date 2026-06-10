#!/bin/bash
## Created by nov05, 2026-06-10

export PROJECT_ID=$(gcloud config get-value project)
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
gcloud config set project $PROJECT_ID  
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
echo
echo "🔹  User: $USER"
echo "🔹  Project ID: $PROJECT_ID"
echo "🔹  Region: $REGION"
echo "🔹  Zone: $ZONE"
echo
gcloud auth list

cat << 'EOF'

========================================================
Task 1. Create a function
========================================================
========================================================
Task 2. Deploy the function
========================================================

EOF

gcloud services enable run.googleapis.com \
  --project=$PROJECT_ID
until gcloud services list --enabled \
  --project=$PROJECT_ID | grep -q run.googleapis.com
do sleep 5; done

gcloud run deploy gcfunction \
    --source=. \
    --region=REGION \
    --allow-unauthenticated \
    --max-instances=5

cat << 'EOF'

========================================================
Task 3. Test the function
========================================================

EOF

gcloud run services proxy gcfunction --region=REGION &
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello World!"}' \
  http://localhost:8080


cat << 'EOF'

========================================================
Task 4. View logs
========================================================

EOF

gcloud logging read \
'resource.type="cloud_run_revision" AND resource.labels.service_name="gcfunction"' \
    --limit=50 \
    --format="table(timestamp,severity,textPayload)"


cat << 'EOF'

========================================================
Task 5. Test your understanding
========================================================

1. Cloud Run functions is a serverless execution environment for event driven services on Google Cloud. 
  True

2. Which type of trigger is used while creating Cloud Run functions in the lab?
  HTTPS
EOF

echo -e "\n✅  All done\n"
