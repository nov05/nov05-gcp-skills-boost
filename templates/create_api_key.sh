#!/bin/bash
## Created by nov05, 2026-06-09 
## Refer to GSP048, ARC132

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
gcloud config set project $PROJECT_ID  

gcloud services enable apikeys.googleapis.com
until gcloud services list --enabled \
  --project=$PROJECT_ID | grep -q apikeys.googleapis.com
do sleep 5; done

export API_DISPLAY_NAME=arc132-api-key

## Delete multiple API keys by the display name
## -r (--no-run-if-empty)
# gcloud alpha services api-keys list \
#     --filter="displayName:$API_DISPLAY_NAME" \
#     --format="value(name)" \
# | xargs -r -n 1 gcloud alpha services api-keys delete \
#     --location=global
gcloud alpha services api-keys list \
  --filter="displayName:gsp323-api-key" \
  --format="value(name)" \
| xargs -r -n 1 -I {} gcloud alpha services api-keys delete "{}"


## Create API key
# gcloud alpha services api-keys create \
#     --display-name="$API_DISPLAY_NAME" 

## Create API key
# export ACCESS_TOKEN=$(gcloud auth print-access-token)
# curl -s -X POST \
#   "https://apikeys.googleapis.com/v2/projects/${PROJECT_ID}/locations/global/keys" \
#   -H "Authorization: Bearer ${ACCESS_TOKEN}" \
#   -H "Content-Type: application/json" \
#   -d @- << EOF
# {
#   "displayName": "${API_DISPLAY_NAME}"
# }
# EOF

## ⚠️ Unfortuantely an API key has to be created via the console to pass the Task 1 check.  
echo -e "\n👉  Create an API key with display name 'arc132-api-key' at"
echo -e "https://console.cloud.google.com/apis/credentials?project=$PROJECT_ID"
echo -e "Search for 'speech' first, then 'translation' when selecting services."
ask_to_proceed

export API_KEY_ID=$(
    gcloud alpha services api-keys list \
        --format="value(name)" \
        --filter "displayName=$API_DISPLAY_NAME")
gcloud services api-keys update $API_KEY_ID \
    --api-target=service=speech.googleapis.com \
    --api-target=service=texttospeech.googleapis.com \
    --api-target=service=translate.googleapis.com
export API_KEY=$(
    gcloud alpha services api-keys get-key-string $API_KEY_ID \
        --format="value(keyString)")