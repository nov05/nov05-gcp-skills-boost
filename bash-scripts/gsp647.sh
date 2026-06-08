#!/bin/bash
## Created by nov05, 2026-06-07  

echo
read -p "👉  Enter Username 2: " USERNAME2
read -p "👉  Enter Project ID 2: " PROJECT_ID2

cat >> ~/.bashrc <<'EOF'
export USERNAME2
export PROJECT_ID2

## Get project id, project number, region, zone
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
  --format='value(projectNumber)')
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export USERNAME=$(gcloud auth list --format="value(account)" --filter="status:ACTIVE")
export ZONE2=$(gcloud compute zones list \
  --filter="region:$REGION" \
  --format="value(name)" | grep -v "$ZONE" | head -n 1)
# export BUCKET="$PROJECT_ID-bucket"

# gcloud config set project $(gcloud projects list --format='value(PROJECT_ID)' --filter='qwiklabs-gcp')
# gcloud config set project $PROJECT_ID  
# gcloud config set compute/region $REGION
# gcloud config set compute/zone $ZONE

echo
echo "🔹  Project ID: $PROJECT_ID"
echo "🔹  Project number: $PROJECT_NUMBER"
echo "🔹  Region: $REGION"
echo "🔹  Zone: $ZONE"
echo "🔹  Zone 2: $ZONE2"
echo "🔹  User: $USER"
echo "🔹  Username: $USERNAME"
# echo "🔹  Bukect: $BUCKET"
echo "🔹  Project ID 2: $PROJECT_ID2"
echo "🔹  Username 2: $USERNAME2"
echo
EOF
source ~/.bashrc

cat << 'EOF'

========================================================
Task 1. Configure the gcloud environment
========================================================

EOF

gcloud auth login --no-launch-browser --quiet
gcloud --version 
gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION 
gcloud config set compute/zone $ZONE 
gcloud compute instances create lab-1 \
  --zone $ZONE \
  --machine-type=e2-standard-2 \
  --metadata enable-oslogin=FALSE

echo -e "\n👉  Switching to zone 2 $ZONE2..."
gcloud config set compute/zone $ZONE2
gcloud config list 
# cat ~/.config/gcloud/configurations/config_default


cat << 'EOF'

========================================================
Task 2. Create and switch between multiple IAM configurations
========================================================

EOF

gcloud config configurations create user2

echo -e "\n👉  Login as User 2 $USERNAME2"
gcloud auth login --no-launch-browser --quiet

gcloud config set project "$PROJECT_ID" \
    --configuration=user2
gcloud config set compute/region "$REGION" \
    --configuration=user2
gcloud config set compute/zone "$ZONE" \
    --configuration=user2

echo -e "\n👉  User 2 $USERNAME2 cannot create an instance in the first project, as the assigned role is basic viewer."
gcloud compute instances create lab-2 \
    --zone "$ZONE" \
    --machine-type=e2-standard-2 || true
echo "🟢  Error is expected."

gcloud config configurations activate default


cat << 'EOF'

========================================================
Task 3. Identify and assign correct IAM permissions
========================================================

EOF

## To view all the roles, run the following inside the SSH session run:
# gcloud iam roles list | grep "name:"

## Examine the compute.instanceAdmin predefined role. Inside the SSH session run:
# gcloud iam roles describe roles/compute.instanceAdmin

gcloud config configurations activate user2
echo -e "\n👉  User 2 $USERNAME2 doesn't have access to Project ID 2 $PROJECT_ID2"
echo n | gcloud config set project "$PROJECT_ID2"

gcloud config configurations activate default
sudo yum -y install epel-release
sudo yum -y install jq
gcloud projects add-iam-policy-binding "$PROJECT_ID2" \
    --member="user:$USERNAME2" \
    --role="roles/viewer"


cat << 'EOF'

========================================================
Task 4. Test that user2 has access
========================================================

EOF

gcloud config configurations activate user2
gcloud config set project $PROJECT_ID2

echo -e "\n👉 Project ID 2 $PROJECT_ID2 VM instances:"
gcloud compute instances list

gcloud config configurations activate default
gcloud iam roles create devops \
    --project "$PROJECT_ID2" \
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
gcloud projects add-iam-policy-binding "$PROJECT_ID2" \
    --member="user:$USERNAME2" \
    --role="roles/iam.serviceAccountUser"
gcloud projects add-iam-policy-binding "$PROJECT_ID2" \
    --member="user:$USERNAME2" \
    --role="projects/$PROJECT_ID2/roles/devops"

gcloud config configurations activate user2
gcloud compute instances create lab-2 \
    --zone "$ZONE" \
    --machine-type=e2-standard-2 \
    --metadata enable-oslogin=FALSE


cat << 'EOF'

========================================================
Task 5. Using a service account
========================================================

EOF

gcloud config configurations activate default
gcloud config set project $PROJECT_ID2
gcloud iam service-accounts create devops --display-name devops

# gcloud iam service-accounts list  --filter "displayName=devops"

SA=$(gcloud iam service-accounts list --format="value(email)" --filter "displayName=devops")
gcloud projects add-iam-policy-binding "$PROJECT_ID2" \
    --member="serviceAccount:$SA" \
    --role="roles/iam.serviceAccountUser"


cat << 'EOF'

========================================================
Task 6. Using the service account with a compute instance
========================================================

EOF

gcloud projects add-iam-policy-binding "$PROJECT_ID2" \
    --member="serviceAccount:$SA" \
    --role="roles/compute.instanceAdmin"

gcloud compute instances create lab-3 \
    --zone "$ZONE" \
    --machine-type=e2-standard-2 \
    --service-account "$SA" \
    --scopes="https://www.googleapis.com/auth/compute" \
    --metadata enable-oslogin=FALSE


cat << 'EOF'

========================================================
Task 7. Test the service account
========================================================

EOF

gcloud compute ssh lab-3 \
    --zone us-central1-c \
    --command "
gcloud config list
gcloud compute instances create lab-4 \
    --zone $ZONE \
    --machine-type=e2-standard-2 \
    --metadata enable-oslogin=FALSE
gcloud compute instances list
"

echo -e "\n✅  All done\n"