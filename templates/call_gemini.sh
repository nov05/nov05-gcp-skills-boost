## Refer to ARC134

## https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/model-versions
export LOCATION=us-central1
export MODEL="gemini-2.5-flash-lite"
export TOKEN=$(gcloud auth print-access-token)
gcloud services enable aiplatform.googleapis.com \
  --project=$PROJECT_ID
until gcloud services list --enabled \
  --project=$PROJECT_ID | grep -q aiplatform.googleapis.com
do sleep 5; done

curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  "https://${REGION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${REGION}/publishers/google/models/${MODEL}:generateContent" \
  -d '{
    "contents": [{"role":"user","parts":[{"text":"What is a service account?"}]}]
  }' | jq -r '.candidates[0].content.parts[0].text'