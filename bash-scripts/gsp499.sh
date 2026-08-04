#!/bin/bash
## Created by nov05, 2026-08-03 

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

## Download the code
gcloud storage cp gs://$PROJECT_ID-bucket/user-authentication-with-iap.zip .
unzip user-authentication-with-iap.zip
cd user-authentication-with-iap




cat << 'EOF'

========================================================
Task 1. Deploy the application and protect it with IAP
========================================================

EOF

## Deploy to Cloud Run
## Open the displayed Service URL in a new browser tab to view the web page. Access is not yet restricted.
cd 1-HelloWorld
cat main.py
gcloud run deploy user-auth-lab --source . --allow-unauthenticated --region="$REGION" --quiet

## 👉 Check my progress

gcloud services enable iap.googleapis.com \
  --project=$PROJECT_ID
until gcloud services list --enabled \
  --project=$PROJECT_ID | grep -q iap.googleapis.com
do sleep 5; done

## Restrict access with IAP
gcloud run services update user-auth-lab \
  --region="$REGION" \
  --iap
until gcloud run services describe user-auth-lab \
  --region="$REGION" \
  | grep -q "Iap Enabled: true"
do sleep 5; done

echo -e "\n\n✅  IAP is enabled for the Cloud Run service. Check it at"
echo -e "https://console.cloud.google.com/security/iap?project=$PROJECT_ID\n"

## Grant the user the IAP-Secured Web App User role
gcloud iap web add-iam-policy-binding \
  --resource-type=cloud-run \
  --service=user-auth-lab \
  --region="$REGION" \
  --member="user:$USER_ID" \
  --role="roles/iap.httpsResourceAccessor"
until gcloud iap web get-iam-policy \
  --resource-type=cloud-run \
  --service=user-auth-lab \
  --region="$REGION" \
  --flatten="bindings[].members" \
  --format="value(bindings.role,bindings.members)" 2>/dev/null \
  | grep -q "roles/iap.httpsResourceAccessor.*user:$USER_ID"
do sleep 5; done

## Test that IAP is turned on
YOUR_URL=$(gcloud run services describe user-auth-lab --region="$REGION" --format='value(status.url)')
echo -e "\n\n👉  Open the service URL: $YOUR_URL/_gcp_iap/clear_login_cookie"
echo -e "When the new Sign in with Google page appears, click Use another account, and re-enter your student credentials.\n"

## 👉 Check my progress




cat << 'EOF'

========================================================
Task 2. Access user identity information
========================================================

EOF

## Deploy to Cloud Run
cd ~/user-authentication-with-iap/2-HelloUser
gcloud run deploy user-auth-lab --source . --region="$REGION" --quiet

## 👉 Check my progress

## Examine the application files
cat main.py
cat templates/index.html

## Test the updated app
YOUR_URL=$(gcloud run services describe user-auth-lab --region="$REGION" --format='value(status.url)')
echo -e "\n\n👉  Open the service URL: $YOUR_URL"

## Turn off IAP
gcloud run services update user-auth-lab \
  --region="$REGION" \
  --no-iap
curl -X GET $YOUR_URL -H "X-Goog-Authenticated-User-Email: totally fake email"



cat << 'EOF'

========================================================
Task 3. Use cryptographic verification
========================================================

EOF

cd ~/user-authentication-with-iap/3-HelloVerifiedUser
## The JWT audience is not an OAuth Client ID. It is the Cloud Run service resource name.
# YOUR_CLIENT_ID="/projects/244489073664/locations/us-central1/services/user-auth-lab"
YOUR_CLIENT_ID="/projects/$PROJECT_NUMBER/locations/$REGION/services/user-auth-lab"
## Deploy the app to Cloud Run, setting the IAP_AUDIENCE environment variable with the Client ID value
gcloud run deploy user-auth-lab \
  --source . \
  --set-env-vars IAP_AUDIENCE="$YOUR_CLIENT_ID" \
  --region="$REGION" \
  --quiet

## 👉 Check my progress

## Examine the application files
cat auth.py
cat main.py

## Restrict access with IAP
gcloud run services update user-auth-lab \
  --region="$REGION" \
  --iap
until gcloud run services describe user-auth-lab \
  --region="$REGION" \
  | grep -q "Iap Enabled: true"
do sleep 5; done

## Remove public access
gcloud run services remove-iam-policy-binding user-auth-lab \
  --region="$REGION" \
  --member="allUsers" \
  --role="roles/run.invoker"
until ! gcloud run services get-iam-policy user-auth-lab \
  --region="$REGION" \
  --flatten="bindings[].members" \
  --format="value(bindings.role,bindings.members)" 2>/dev/null \
  | grep -q "roles/run.invoker.*allUsers"
do sleep 5; done

## Grant the IAP service agent permission to invoke your Cloud Run service
gcloud run services add-iam-policy-binding user-auth-lab \
  --member="serviceAccount:service-$PROJECT_NUMBER@gcp-sa-iap.iam.gserviceaccount.com" \
  --role="roles/run.invoker" \
  --region="$REGION"
until gcloud run services get-iam-policy user-auth-lab \
  --region="$REGION" \
  --flatten="bindings[].members" \
  --format="value(bindings.role,bindings.members)" 2>/dev/null \
  | grep -q "roles/run.invoker.*service-$PROJECT_NUMBER@gcp-sa-iap.iam.gserviceaccount.com"
do sleep 5; done

## Grant the user the IAP-Secured Web App User role
gcloud iap web add-iam-policy-binding \
  --resource-type=cloud-run \
  --service=user-auth-lab \
  --region="$REGION" \
  --member="user:$USER_ID" \
  --role="roles/iap.httpsResourceAccessor"
until gcloud iap web get-iam-policy \
  --resource-type=cloud-run \
  --service=user-auth-lab \
  --region="$REGION" \
  --flatten="bindings[].members" \
  --format="value(bindings.role,bindings.members)" 2>/dev/null \
  | grep -q "roles/iap.httpsResourceAccessor.*user:$USER_ID"
do sleep 5; done

## Refresh the application page. Verify that the cryptographically signed email 
## and user ID are now correctly displayed and verified
YOUR_URL=$(gcloud run services describe user-auth-lab --region="$REGION" --format='value(status.url)')
echo -e "\n\n👉  Open the service URL: $YOUR_URL"



echo -e "\n✅  All done\n"
