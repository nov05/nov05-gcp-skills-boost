#!/bin/bash
## Created by nov05, 2026-06-08

## Get project id, project number, region, zone
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
  --format='value(projectNumber)')
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
gcloud config set project $PROJECT_ID  
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
echo
echo "🔹  Project ID: $PROJECT_ID"
echo "🔹  Project number: $PROJECT_NUMBER"
echo "🔹  Region: $REGION"
echo "🔹  Zone: $ZONE"
echo "🔹  User: $USER"
echo

cat << 'EOF'

========================================================
Task 1. Enable and Explore Gemini (optional)
========================================================

EOF

export MODEL="gemini-1.5-flash"
export TOKEN=$(gcloud auth print-access-token)
curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  "https://${REGION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${REGION}/publishers/google/models/${MODEL}:generateContent" \
  -d '{
    "contents": [
      {
        "role": "user",
        "parts": [
          {
            "text": "What is a service account?"
          }
        ]
      }
    ]
  }'
curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  "https://${REGION}-aiplatform.googleapis.com/v1/projects/${PROJECT_ID}/locations/${REGION}/publishers/google/models/${MODEL}:generateContent" \
  -d '{
    "contents": [{"role":"user","parts":[{"text":"What is a service account?"}]}]
  }' | jq -r '.candidates[0].content.parts[0].text'


cat << 'EOF'

========================================================
Task 2. Create a service account using the gcloud CLI
========================================================

EOF

## Refer to GSP647
gcloud iam roles create devops \
    --project $PROJECT_ID \
    --permissions \
    "compute.instances.create,\
compute.instances.delete,\
compute.instances.start,\
compute.instances.stop,\
compute.instances.update,\
compute.disks.create,\
compute.subnetworks.use,\
compute.subnetworks.useExternalIp,\
compute.instances.setMetadata,\
compute.instances.setServiceAccount"
until gcloud iam roles describe devops --project $PROJECT_ID >/dev/null 2>&1
do sleep 5; done

cat << 'EOF'

========================================================
Task 3. Grant IAM permissions to a service account using the gcloud CLI
========================================================

EOF

## Refer to GSP647
export SA=$(gcloud iam service-accounts list \
    --format="value(email)" \
    --filter "displayName=devops")
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$SA \
    --role=roles/iam.serviceAccountUser    
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$SA \
    --role=roles/compute.instanceAdmin
until gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:$SA AND bindings.role:roles/compute.instanceAdmin" \
  --format="value(bindings.role)" | grep -q .
do sleep 5; done

cat << 'EOF'

========================================================
Task 4. Create a compute instance with a service account attached using gcloud
========================================================

EOF
## Refer to GSP647

gcloud compute instances create vm-2 \
    --zone $ZONE \
    --machine-type=e2-standard-2 \
    --service-account $SA \
    --scopes="https://www.googleapis.com/auth/compute"

## SSH into the vm-2 VM instance. Try to create and list an instance 
## from vm-2 to verify you have the necessary permissions via the service account.
gcloud compute ssh vm-2 \
    --zone $ZONE \
    --quiet \
    --command "
gcloud config list &&
gcloud compute instances create vm-3 \
    --zone $ZONE \
    --machine-type=e2-standard-2 &&
echo -e '\n👉  VM instances:' &&
gcloud compute instances list
"

cat << 'EOF'

========================================================
Task 5. Create a custom role using a YAML file
========================================================

EOF
## Refer to GSP190

echo 'title: "Role ARC134"
description: "BigQuery Access for Service Account"
stage: "ALPHA"
includedPermissions:
- cloudsql.instances.connect
- cloudsql.instances.get' > role-definition.yaml

gcloud iam roles create role-arc134 \
    --project $PROJECT_ID \
    --file role-definition.yaml

## role-arc134 is not used later.

cat << 'EOF'

========================================================
Task 6. Use the client libraries to access BigQuery from a service account
========================================================

EOF
## Refer to GSP199

gcloud iam service-accounts create bigquery-qwiklab \
  --display-name="bigquery-qwiklab"
until gcloud iam service-accounts describe \
  "bigquery-qwiklab@$PROJECT_ID.iam.gserviceaccount.com" >/dev/null 2>&1
do sleep 5; done

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:bigquery-qwiklab@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/bigquery.dataViewer"
until gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --format="value(bindings.role, bindings.members)" 2>/dev/null \
  | grep -q "roles/bigquery.dataViewer.*bigquery-qwiklab@$PROJECT_ID.iam.gserviceaccount.com"
do sleep 5; done

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:bigquery-qwiklab@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/bigquery.user"
until gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --format="value(bindings.role, bindings.members)" 2>/dev/null \
  | grep -q "roles/bigquery.user.*bigquery-qwiklab@$PROJECT_ID.iam.gserviceaccount.com"
do sleep 5; done

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
sudo apt-get install -y -qq git python3-pip python3-venv
python3 -m venv ~/bq-env
source ~/bq-env/bin/activate
~/bq-env/bin/pip install --quiet --upgrade pip
~/bq-env/bin/pip install --quiet \
    google-cloud-bigquery pyarrow pandas db-dtypes

## Create Python script
cat > query.py <<'EOF_PY'
from google.auth import compute_engine
from google.cloud import bigquery

## Compute Engine metadata server already supplies credentials.
## However, we'll leave the code unchanged to match the lab instructions.
print("👉  Initializing BigQuery client...")
credentials = compute_engine.Credentials(
    service_account_email='YOUR_SERVICE_ACCOUNT')

query = '''
SELECT name, SUM(number) as total_people
FROM "bigquery-public-data.usa_names.usa_1910_2013"
WHERE state = 'TX'
GROUP BY name, state
ORDER BY total_people DESC
LIMIT 20
'''
client = bigquery.Client(
    project='YOUR_PROJECT_ID',
    credentials=credentials)
print(client.query(query).to_dataframe())
EOF_PY

## Replace placeholders
sed -i -e "s/PROJECT_ID/$(gcloud config get-value project)/g" query.py
sed -i -e "s/YOUR_SERVICE_ACCOUNT/bigquery-qwiklab@$(gcloud config get-value project).iam.gserviceaccount.com/g" query.py

## Execute the script
# python3 query.py
~/bq-env/bin/python query.py
EOF

gcloud compute scp bigquery.sh bigquery-instance:/tmp \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --quiet

gcloud compute ssh bigquery-instance \
  --project=$PROJECT_ID \
  --zone=$ZONE \
  --quiet \
  --command="chmod +x /tmp/bigquery.sh && /tmp/bigquery.sh"

echo -e "\n✅  All done\n"