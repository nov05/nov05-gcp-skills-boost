## 👉 For development

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/dev/bash-scripts/gsp315.sh
sudo chmod +x gsp315.sh
./gsp315.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

## 👉 Logs

* 2026-06-11 Bash script `gsp081.sh` created



## Tips

```bash
gcloud storage service-agent --project=$PROJECT_ID
```

* Find the correct Cloud Storage service agent automatically.  
  Grant Pub/Sub Publisher role.  

```bash
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
GCS_SERVICE_AGENT="service-${PROJECT_NUMBER}@gs-project-accounts.iam.gserviceaccount.com"
echo $GCS_SERVICE_AGENT
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$GCS_SERVICE_AGENT" \
  --role="roles/pubsub.publisher"
```
```text
service-300445648948@gs-project-accounts.iam.gserviceaccount.com
Updated IAM policy for project [qwiklabs-gcp-00-ddcd2a10d829].
bindings:
- members:
  - serviceAccount:qwiklabs-gcp-00-ddcd2a10d829@qwiklabs-gcp-00-ddcd2a10d829.iam.gserviceaccount.com
  role: roles/bigquery.admin
- members:
  - serviceAccount:300445648948@cloudbuild.gserviceaccount.com
  role: roles/cloudbuild.builds.builder
- members:
  - serviceAccount:service-300445648948@gcp-sa-cloudbuild.iam.gserviceaccount.com
  role: roles/cloudbuild.serviceAgent
- members:
  - serviceAccount:300445648948@cloudservices.gserviceaccount.com
  role: roles/compute.instanceGroupManagerServiceAgent
- members:
  - serviceAccount:service-300445648948@compute-system.iam.gserviceaccount.com
  role: roles/compute.serviceAgent
- members:
  - serviceAccount:300445648948-compute@developer.gserviceaccount.com
  - serviceAccount:300445648948@cloudservices.gserviceaccount.com
  role: roles/editor
- members:
  - serviceAccount:admiral@qwiklabs-services-prod.iam.gserviceaccount.com
  - serviceAccount:qwiklabs-gcp-00-ddcd2a10d829@qwiklabs-gcp-00-ddcd2a10d829.iam.gserviceaccount.com
  - user:student-02-1e34634e62e5@qwiklabs.net
  role: roles/owner
- members:
  - serviceAccount:service-300445648948@gs-project-accounts.iam.gserviceaccount.com
  role: roles/pubsub.publisher
- members:
  - user:student-02-1e34634e62e5@qwiklabs.net
  role: roles/resourcemanager.projectIamAdmin
- members:
  - serviceAccount:service-300445648948@serverless-robot-prod.iam.gserviceaccount.com
  role: roles/run.serviceAgent
- members:
  - serviceAccount:qwiklabs-gcp-00-ddcd2a10d829@qwiklabs-gcp-00-ddcd2a10d829.iam.gserviceaccount.com
  role: roles/storage.admin
- members:
  - user:student-02-1e34634e62e5@qwiklabs.net
  - user:student-02-a8fef0386f2b@qwiklabs.net
  role: roles/viewer
etag: BwZT-tOdP_A=
version: 1
```





