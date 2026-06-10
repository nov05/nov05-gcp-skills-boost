#!/bin/bash
## Created by nov05, 2026-06-09

ask_to_proceed() {
    while true; do
        read -rp "Ready to proceed? (y): " answer
        [[ "$answer" =~ ^[Yy]$ ]] && break
    done
}

## Get project id, project number, region, zone
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
Task 1. Create an API key
========================================================

EOF
## Refer to GSP049

gcloud services enable apikeys.googleapis.com
until gcloud services list --enabled \
  --project=$PROJECT_ID | grep -q apikeys.googleapis.com
do sleep 5; done

## Delete multiple API keys by the display name
gcloud alpha services api-keys list \
  --filter="displayName:gsp048-api-key" \
  --format="value(name)" \
| xargs -n 1 gcloud alpha services api-keys delete

gcloud alpha services api-keys create \
    --display-name="gsp048-api-key" 
export KEY_ID=$(
    gcloud alpha services api-keys list \
        --format="value(name)" \
        --filter "displayName=gsp048-api-key")
gcloud services api-keys update $KEY_ID \
    --api-target=service=speech.googleapis.com
export API_KEY=$(
    gcloud alpha services api-keys get-key-string $KEY_ID \
        --format="value(keyString)")

cat << 'EOF'

========================================================
Task 2. Create your API request
========================================================

EOF

cat << 'EOF' > request.json
{
  "config": {
      "encoding":"FLAC",
      "languageCode": "en-US"
  },
  "audio": {
      "uri":"gs://cloud-samples-data/speech/brooklyn_bridge.flac"
  }
}
EOF
cat request.json

echo -e "\n👉  Check the progress in the lab.\n"
ask_to_proceed

cat << 'EOF'

========================================================
Task 3. Call the Speech-to-Text API
========================================================

EOF

echo '#!/bin/bash' > task.sh
echo "export API_KEY=$API_KEY" >> task.sh
cat << 'EOF' >> task.sh
curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
"https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" > result.json
echo -e "\n👉  Check result.json\n"
cat result.json
EOF

## Copy files to the VM instance
gcloud compute scp task.sh request.json linux-instance:~ \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --quiet

gcloud compute ssh linux-instance \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --quiet \
  --command="chmod +x ~/task.sh && ~/task.sh"

echo -e "\n👉  Check the progress in the lab.\n"
ask_to_proceed

cat << 'EOF'

========================================================
Task 4. Speech-to-Text transcription in different languages
========================================================

EOF

rm -f request.json
cat << 'EOF' > request.json
 {
  "config": {
      "encoding":"FLAC",
      "languageCode": "fr"
  },
  "audio": {
      "uri":"gs://cloud-samples-data/speech/corbeau_renard.flac"
  }
}
EOF
cat request.json

gcloud compute scp task.sh request.json linux-instance:~ \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --quiet

gcloud compute ssh linux-instance \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --quiet \
  --command="chmod +x ~/task.sh && ~/task.sh"

echo -e "\n👉  Check the progress in the lab.\n"
ask_to_proceed


echo -e "\n✅  All done\n"