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

* Refer to GSP049 for API key usage

```bash
gcloud services enable apikeys.googleapis.com; sleep 10
gcloud alpha services api-keys create \
    --display-name="gsp049-api-key" 
export KEY_ID=$(
    gcloud alpha services api-keys list \
        --format="value(name)" \
        --filter "displayName=gsp049-api-key")
export API_KEY=$(
    gcloud alpha services api-keys get-key-string $KEY_ID \
        --format="value(keyString)")

TEXT="My%20name%20is%20Steve"
curl "https://translation.googleapis.com/language/translate/v2?target=es&key=${API_KEY}&q=${TEXT}"
```


* Refer to GSP222 for access token usage

```bash
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