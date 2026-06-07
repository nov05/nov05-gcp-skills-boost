#!/bin/bash
## Created by nov05, 2026-06-07 

set -euo pipefail

# cat >> ~/.bashrc <<'EOF'
## Get project id, project number, region, zone
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
  --format='value(projectNumber)')
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
# export USER_EMAIL=$(gcloud auth list --format="value(account)" --filter="status:ACTIVE")
# export BUCKET="$PROJECT_ID-bucket"
# gcloud config set project $(gcloud projects list --format='value(PROJECT_ID)' --filter='qwiklabs-gcp')
gcloud config set project $PROJECT_ID  
gcloud config set compute/region $REGION
echo
echo "🔹  Project ID: $PROJECT_ID"
echo "🔹  Project number: $PROJECT_NUMBER"
echo "🔹  Region: $REGION"
echo "🔹  Zone: $ZONE"
echo "🔹  User: $USER"
# echo "🔹  User email: $USER_EMAIL"
# echo "🔹  Bukect: $BUCKET"
echo
# EOF
# source ~/.bashrc

cat << 'EOF'

========================================================
Task 1. Create and manage service accounts
========================================================

EOF

gcloud iam service-accounts create my-sa-123 \
    --display-name "my service account"
sleep 20

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member serviceAccount:my-sa-123@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
    --role roles/editor
sleep 20

cat << 'EOF'

========================================================
Task 2. Use the client libraries to access BigQuery using a service account
========================================================

EOF

gcloud iam service-accounts create bigquery-qwiklab \
  --display-name="bigquery-qwiklab"
sleep 20

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member="serviceAccount:bigquery-qwiklab@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/bigquery.dataViewer"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member="serviceAccount:bigquery-qwiklab@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/bigquery.user"
sleep 20

gcloud compute instances create bigquery-instance \
  --project="$PROJECT_ID" \
  --zone="$ZONE" \
  --machine-type="e2-medium" \
  --subnet="default" \
  --service-account="bigquery-qwiklab@$PROJECT_ID.iam.gserviceaccount.com" \
  --scopes="https://www.googleapis.com/auth/cloud-platform" \
  --image-family="debian-12" \
  --image-project="debian-cloud" \
  --boot-disk-size="10GB" \
  --boot-disk-type="pd-standard" \
  --metadata=enable-oslogin=FALSE
until gcloud compute ssh bigquery-instance \
    --zone=$ZONE \
    --command="echo ready" >/dev/null 2>&1; do
  sleep 5
done

cat > bigquery.sh <<'EOF'
#!/bin/bash

## Install required packages
sudo apt-get update -qq
sudo apt-get install -y -qq git python3-pip

python3 -m venv ~/bq-env
source ~/bq-env/bin/activate

## Upgrade pip and install Python libraries
## On Debian 12, some images enforce PEP 668, which protect the system Python from being modified by pip.
## Without setting --break-system-packages or using a virtual environment, you may see an "externally-managed-environment" error.
pip3 install --quiet --upgrade pip
pip3 install --quiet google-cloud-bigquery pyarrow pandas db-dtypes

## Create Python script
cat > query.py <<'EOF_PY'
from google.auth import compute_engine
from google.cloud import bigquery
import pandas as pd

## Compute Engine metadata server already supplies credentials.
## However, we'll leave the code unchanged to match the lab instructions.
print("👉  Initializing BigQuery client...")
credentials = compute_engine.Credentials(
    service_account_email='YOUR_SERVICE_ACCOUNT')

## If Google eventually retires that legacy dataset, the modern equivalent is:
## FROM `bigquery-public-data.samples.natality`
query = '''SELECT
  year,
  COUNT(*) as num_babies
FROM
  publicdata.samples.natality
WHERE
  year > 2000
GROUP BY
  year
ORDER BY
  year
'''

client = bigquery.Client(
  project='PROJECT_ID',
  credentials=credentials)

print("👉  Executing BigQuery job...")
df = client.query(query).to_dataframe()

print("👉  Query results:")
print(df.to_string(index=False))
EOF_PY

## Replace placeholders
sed -i -e "s/PROJECT_ID/$(gcloud config get-value project)/g" query.py
sed -i -e "s/YOUR_SERVICE_ACCOUNT/bigquery-qwiklab@$(gcloud config get-value project).iam.gserviceaccount.com/g" query.py

## Execute the script
python3 query.py
EOF

gcloud compute scp bigquery.sh bigquery-instance:/tmp \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --quiet

gcloud compute ssh bigquery-instance \
  --project=$DEVSHELL_PROJECT_ID \
  --zone=$ZONE \
  --quiet \
  --command="chmod +x /tmp/bigquery.sh && /tmp/bigquery.sh"

echo -e "\n✅  All done\n"
