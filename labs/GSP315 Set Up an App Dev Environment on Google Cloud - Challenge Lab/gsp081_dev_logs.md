## 👉 For development

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/dev/bash-scripts/gsp315.sh
sudo chmod +x gsp315.sh
./gsp315.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```





## Tips:

* Find the correct Cloud Storage service agent automatically

```bash
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
GCS_SERVICE_AGENT="service-${PROJECT_NUMBER}@gs-project-accounts.iam.gserviceaccount.com"
echo $GCS_SERVICE_AGENT
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${GCS_SERVICE_AGENT}" \
  --role="roles/pubsub.publisher"
```
```text
Your active configuration is: [cloudshell-2725]
service-437182158726@gs-project-accounts.iam.gserviceaccount.com
Updated IAM policy for project [qwiklabs-gcp-04-dfb5a5ec8990].
bindings:
...
```

* Grant Pub/Sub Publisher role

```bash
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
EVENTARC_AGENT="service-${PROJECT_NUMBER}@gcp-sa-eventarc.iam.gserviceaccount.com"
echo $EVENTARC_AGENT
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${EVENTARC_AGENT}" \
  --role="roles/pubsub.publisher"
```
```text
Your active configuration is: [cloudshell-2725]   
service-437182158726@gcp-sa-eventarc.iam.gserviceaccount.com    
Updated IAM policy for project [qwiklabs-gcp-04-dfb5a5ec8990].    
bindings:    
...   
```






## 👉 Logs

* 2026-06-11 Bash script `gsp081.sh` created