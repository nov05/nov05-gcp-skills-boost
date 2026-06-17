## 👉 For development

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/dev/bash-scripts/gsp323.sh
sudo chmod +x gsp323.sh
./gsp323.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```


## 👉 Logs

* 2026-06-09 Script `gsp323.sh` created and tested


## Tips

🟢⚠️ Issue solved: `-H "x-goog-user-project: $PROJECT_ID"`

https://docs.cloud.google.com/docs/authentication/troubleshoot-adc#user-creds-client-based  
https://github.com/golang/oauth2/issues/702#issuecomment-2083811446  

```bash
## Authenticated via access token
gcloud auth application-default revoke --quiet
gcloud auth application-default login --quiet 
gcloud auth application-default set-quota-project $PROJECT_ID
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  "https://speech.googleapis.com/v1/speech:recognize" \
  -d @request.json > result.json
```
```bash
{
  "error": {
    "code": 403,
    "message": "Your application is authenticating by using local Application Default Credentials. The speech.googleapis.com API requires a quota project, which is not set by default. To learn how to set your quota project, see https://cloud.google.com/docs/authentication/adc-troubleshooting/user-creds .",
    "status": "PERMISSION_DENIED",
    "details": [
      {
        "@type": "type.googleapis.com/google.rpc.ErrorInfo",
        "reason": "SERVICE_DISABLED",
        "domain": "googleapis.com",
        "metadata": {
          "service": "speech.googleapis.com",
          "consumer": "projects/618104708054"
        }
      },
      {
        "@type": "type.googleapis.com/google.rpc.LocalizedMessage",
        "locale": "en-US",
        "message": "Your application is authenticating by using local Application Default Credentials. The speech.googleapis.com API requires a quota project, which is not set by default. To learn how to set your quota project, see https://cloud.google.com/docs/authentication/adc-troubleshooting/user-creds ."
      }
    ]
  }
}
```