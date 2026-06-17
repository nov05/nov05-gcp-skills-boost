* Created by nov05, 2026-06-09 

👉 API Key vs. Access Token

| Feature                                     | API Key | Access Token |
| ------------------------------------------- | ------- | ------------ |
| Identifies project                          | ✅       | ✅            |
| Identifies user/service account             | ❌       | ✅            |
| Uses IAM permissions                        | ❌       | ✅            |
| Sent in URL                                 | ✅       | ❌            |
| Sent in Authorization header                | ❌       | ✅            |
| Expires automatically                       | ❌       | ✅            |
| Common in beginner labs                     | ✅       | Sometimes    |
| Common in production Google Cloud workloads | Rare    | ✅            |

<br>  

* Refer to GSP048, GSP049 for API key usage

```bash
## Delete multiple API keys by the display name
## -r (--no-run-if-empty)
export API_DISPLAY_NAME=gsp048-api-key
gcloud alpha services api-keys list \
    --filter="displayName:$API_DISPLAY_NAME" \
    --format="value(name)" \
| xargs -r -n 1 gcloud alpha services api-keys delete \
    --location=global

gcloud alpha services api-keys create \
    --display-name="$API_DISPLAY_NAME" 
export API_KEY_ID=$(
    gcloud alpha services api-keys list \
        --format="value(name)" \
        --filter "displayName=$API_DISPLAY_NAME")
gcloud services api-keys update $API_KEY_ID \
    --api-target=service=speech.googleapis.com
export API_KEY=$(
    gcloud alpha services api-keys get-key-string $API_KEY_ID \
        --format="value(keyString)")

TEXT="My%20name%20is%20Steve"
curl "https://translation.googleapis.com/language/translate/v2?target=es&key=${API_KEY}&q=${TEXT}"
```


* Refer to GSP222, GSP107 for access token usage

```bash
## GSP222
export SA="tts-qwiklab@$PROJECT_ID.iam.gserviceaccount.com"
gcloud iam service-accounts describe "$SA" >/dev/null 2>&1 || \
gcloud iam service-accounts create tts-qwiklab
until gcloud iam service-accounts describe "$SA" >/dev/null 2>&1
do sleep 5; done

## Authenticating by using local Application Default Credentials
gcloud iam service-accounts keys create tts-qwiklab.json \
    --iam-account "$SA"
export GOOGLE_APPLICATION_CREDENTIALS=tts-qwiklab.json

## ⚠️ After activate the service account, you have to set it as the current account. 
gcloud auth activate-service-account --key-file=tts-qwiklab.json
gcloud config set account $SA
export TOKEN=$(gcloud auth print-access-token)

echo -e "\n👉  List the voices available when you use the Text-to-Speech API to create synthetic speech.\n"
curl -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json; charset=utf-8" \
    "https://texttospeech.googleapis.com/v1/voices"
```

```bash
## GSP107: /projects/$PROJECT_ID 
curl -s \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  https://dlp.googleapis.com/v2/projects/$PROJECT_ID/content:deidentify \
  -d @new-inspect-file.json -o redact-output.txt
cat redact-output.txt
```

* Refer to GSP323 for both access token and API key usage when calling the speech APIs.

```bash
## Authenticated via access token 
## -H "x-goog-user-project: $PROJECT_ID" ✅
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "x-goog-user-project: $PROJECT_ID" \
  "https://speech.googleapis.com/v1/speech:recognize" \
  -d @request.json > result.json
echo -e "\n👉  Check the result.\n"
cat result.json | jq .
```

```bash
## Authenticate via API key 
gcloud services disable apikeys.googleapis.com --project $PROJECT_ID --force
gcloud services enable apikeys.googleapis.com --project $PROJECT_ID
until gcloud services list --enabled \
  --project=$PROJECT_ID | grep -q apikeys.googleapis.com
do sleep 5; done
## Delete multiple API keys by the display name
gcloud alpha services api-keys list \
  --filter="displayName:gsp323-api-key" \
  --format="value(name)" \
| xargs -n 1 -I {} gcloud alpha services api-keys delete "{}"
gcloud alpha services api-keys create \
  --display-name="gsp323-api-key" 
export KEY_ID=$(
  gcloud alpha services api-keys list \
    --format="value(name)" \
    --filter "displayName=gsp323-api-key")
gcloud services api-keys update $KEY_ID \
  --api-target=service=speech.googleapis.com \
  --api-target=service=language.googleapis.com
export API_KEY=$(
  gcloud alpha services api-keys get-key-string $KEY_ID \
    --format="value(keyString)")
curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
"https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" > result.json
echo -e "\n👉  Check the result.\n"
cat result.json | jq .
```