#!/bin/bash
## Created by nov05, 2026-06-16

export USER_ID=$(gcloud auth list --format="value(account)" --filter="status:ACTIVE")
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
  --format='value(projectNumber)')
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export BUCKET="$PROJECT_ID-bucket"
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
Task 1. Clone the repo and enable APIs
========================================================

EOF

git clone https://github.com/googleapis/synthtool
cd synthtool/tests/fixtures/nodejs-dlp/samples/ && npm install
gcloud services disable dlp.googleapis.com cloudkms.googleapis.com \
  --project $PROJECT_ID --force
gcloud services enable dlp.googleapis.com cloudkms.googleapis.com \
  --project $PROJECT_ID
until enabled=$(gcloud services list --enabled --project=$PROJECT_ID); \
  echo "$enabled" | grep -q dlp.googleapis.com && \
  echo "$enabled" | grep -q cloudkms.googleapis.com
do sleep 5; done


cat << 'EOF'

========================================================
Task 2. Inspect strings and files
========================================================

EOF

node inspectString.js $PROJECT_ID \
  "My email address is jenny@somedomain.com and you can call me at 555-867-5309" \
  > inspected-string.txt
echo -e "\n👉  Check 'inspected-string.txt'.\n"
cat inspected-string.txt
echo -e "\n👉  Check 'resources/accounts.txt'.\n"
cat resources/accounts.txt
node inspectFile.js $PROJECT_ID resources/accounts.txt > inspected-file.txt
echo -e "\n👉  Check 'inspected-file.txt'.\n"
cat inspected-file.txt
gsutil cp inspected-string.txt gs://$BUCKET
gsutil cp inspected-file.txt gs://$BUCKET

cat << 'EOF'

========================================================
Task 3. De-identification
========================================================

EOF

node deidentifyWithMask.js $PROJECT_ID \
  "My order number is F12312399. Email me at anthony@somedomain.com" \
  > de-identify-output.txt
echo -e "\n👉  Check 'de-identify-output.txt'.\n"
cat de-identify-output.txt
gsutil cp de-identify-output.txt gs://$BUCKET

cat << 'EOF'

========================================================
Task 4. Redact strings and images
========================================================

EOF

node redactText.js $PROJECT_ID \
  "Please refund the purchase to my credit card 4012888888881881" CREDIT_CARD_NUMBER \
  > redacted-string.txt
echo -e "\n👉  Check 'redacted-string.txt'.\n"
cat redacted-string.txt
node redactImage.js $PROJECT_ID resources/test.png "" PHONE_NUMBER ./redacted-phone.png
node redactImage.js $PROJECT_ID resources/test.png "" EMAIL_ADDRESS ./redacted-email.png
gsutil cp redacted-string.txt gs://$BUCKET
gsutil cp redacted-phone.png gs://$BUCKET
gsutil cp redacted-email.png gs://$BUCKET


echo -e "\n✅  All done\n"