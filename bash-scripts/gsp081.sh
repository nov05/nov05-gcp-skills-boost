#!/bin/bash
## Created by nov05, 2026-06-10

set -e

ask_to_proceed() {
    echo
    while true; do
        read -rp "Ready to proceed? (y): " answer
        [[ "$answer" =~ ^[Yy]$ ]] && break
    done
    echo
    echo
}

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

echo -e "\n👉  Enabling services...\n"
gcloud services enable run.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  --project=$PROJECT_ID
until enabled=$(gcloud services list --enabled --project=$PROJECT_ID); \
  echo "$enabled" | grep -q run.googleapis.com && \
  echo "$enabled" | grep -q artifactregistry.googleapis.com && \
  echo "$enabled" | grep -q cloudbuild.googleapis.com
do sleep 5; done

# mkdir myfunc && cd myfunc
# cat > index.js << 'EOF'
# const functions = require('@google-cloud/functions-framework');
# functions.http('helloHttp', (req, res) => {
#   res.set('Content-Type', 'text/plain');
#   res.send(`Hello ${req.query.name || req.body.name || 'World'}!`);
# });
# EOF
# cat > package.json << 'EOF'
# {
#   "dependencies": {
#     "@google-cloud/functions-framework": "^3.0.0"
#   }
# }
# EOF
# cd ..
# echo -e "\n👉  Deploying Cloud Run function 'gcfunction'...\n"
## ⚠️ It may need retry a couple of times.
# gcloud functions deploy gcfunction \
#   --gen2 \
#   --runtime=nodejs22 \
#   --region=$REGION \
#   --source=./myfunc \
#   --entry-point=helloHttp \
#   --trigger-http \
#   --allow-unauthenticated \
#   --max-instances=5 \
#   --timeout=300 \
#   --memory=512Mi \
#   --cpu=1 \
#   --concurrency=80

## ⚠️ The function has to be created via console to pass the lab check.
echo -e "\n👉  Create and deploy Cloud Run funcion 'gcfunction' at"  
echo -e "https://console.cloud.google.com/run/services?project=$PROJECT_ID\n"
ask_to_proceed

# gcloud run services update gcfunction \
#   --region=$REGION \
#   --max-instances=8

echo -e "\n👉  Check revisions:\n"
gcloud run revisions list \
  --service=gcfunction \
  --region=$REGION \
  --sort-by="~metadata.creationTimestamp"
  # --format="value(name)"
  # --limit=1

: << 'COMMENT'
If the function is created via Cloud Shell.
  REVISION: gcfunction-00001-gew
  ACTIVE: yes
  SERVICE: gcfunction
  DEPLOYED: 2026-06-10 20:35:33 UTC
  DEPLOYED BY: service-660504225966@gcf-admin-robot.iam.gserviceaccount.com
If it is created via Console.
  REVISION: gcfunction-00001-p62
  ACTIVE: yes
  SERVICE: gcfunction
  DEPLOYED: 2026-06-10 20:42:28 UTC
  DEPLOYED BY: student-04-dcd619cc3816@qwiklabs.net
COMMENT

echo -e "\n👉  Check Cloud Run function 'gcfunction' configurations:\n"
gcloud run services describe gcfunction \
  --region=$REGION \
  --format="yaml(spec.template)"


cat << 'EOF'

========================================================
Task 3. Test the function
========================================================

EOF

## If the function is created via Cloud Shell, in the console you will find this type of URL.
# curl -X POST "https://${REGION}-${PROJECT_ID}.cloudfunctions.net/gcfunction" \
# -H "Authorization: bearer $(gcloud auth print-identity-token)" \
# -H "Content-Type: application/json" \
# -d '{
#   "name": "Developer"
# }'

## E.g. https://gcfunction-d27fjhcvqq-wn.a.run.app
URL=$(gcloud run services describe gcfunction \
  --region $REGION \
  --format='value(status.url)')
curl -X POST "$URL" \
-H "Authorization: bearer $(gcloud auth print-identity-token)" \
-H "Content-Type: application/json" \
-d '{
  "name": "Developer"
}'

cat << 'EOF'

========================================================
Task 4. View logs
========================================================

EOF

gcloud logging read \
'resource.type="cloud_run_revision" AND resource.labels.service_name="gcfunction"' \
    --limit=20 \
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
