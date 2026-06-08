#!/bin/bash
## Created by nov05, 2026-06-07  

ask_to_proceed() {
    while true; do
        read -rp "Ready to proceed? (y): " answer
        [[ "$answer" =~ ^[Yy]$ ]] && break
    done
}

echo
# echo "Tips: Finc Zone 1 in Task 1 'gcloud config set compute/zone Zone1'."
echo "Tips: Find Zone 2 in Task 4 'gcloud compute instances create lab-2 --zone Zone2 --machine-type=e2-standard-2'."
read -p "👉  Enter Username 1: " USERID
read -p "👉  Enter Username 2: " USERID2
read -p "👉  Enter Project ID 2: " PROJECTID2
# read -p "👉  Enter Zone 1: " ZONE
read -p "👉  Enter Zone 2: " ZONE2
export USERID USERID2 PROJECTID2 ZONE ZONE2
export PROJECTID=$(gcloud config get-value project)
# export REGION=$(echo "$ZONE" | sed 's/-[^-]*$//')
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
echo
echo "🔹  Username 1: $USERID"
echo "🔹  Username 2: $USERID2"
echo "🔹  Project ID 1: $PROJECTID"
echo "🔹  Project ID 2: $PROJECTID2"
echo "🔹  Region: $REGION"
echo "🔹  Zone 1: $ZONE"
echo "🔹  Zone 2: $ZONE2"
echo

cat << 'EOF'

========================================================
Task 1. Configure the gcloud environment
========================================================

EOF

echo -e "\n👉  Login as Username $USERID"
gcloud auth login --no-launch-browser --quiet
# gcloud --version 
gcloud config set compute/region $REGION 
gcloud config set compute/zone $ZONE 
gcloud compute instances create lab-1 \
  --zone $ZONE \
  --machine-type=e2-standard-2

# export NEWZONE=$(gcloud compute zones list \
#   --filter="region:$REGION" \
#   --format="value(name)" | grep -v "$ZONE" | head -n 1)
export NEWZONE=$(gcloud compute zones list \
    --filter="name~'^$REGION'" \
    --format="value(name)" | grep -v "^$ZONE$" | head -n 1)
echo -e "\n👉  Switching to a new zone $NEWZONE..."
gcloud config set compute/zone $NEWZONE
# gcloud config list 
# cat ~/.config/gcloud/configurations/config_default
echo -e "\n👉  Check the progress for 'Task 1 - Update the default zone' in the lab."
ask_to_proceed

cat << 'EOF'

========================================================
Task 2. Create and switch between multiple IAM configurations
========================================================

EOF

gcloud config configurations create user2 --quiet
gcloud config configurations activate user2

echo -e "\n👉  Login as Username 2 $USERID2"
gcloud auth login --no-launch-browser --quiet
# gcloud config set account "$USERID2" \
#     --configuration=user2
gcloud config set project $PROJECTID \
    --configuration=user2
gcloud config set compute/region $REGION \
    --configuration=user2
gcloud config set compute/zone $ZONE \
    --configuration=user2

echo "export ZONE2=$ZONE2" >> ~/.bashrc
. ~/.bashrc
echo -e "\n👉  User 2 $USERID2 cannot create an instance in the first project, as the assigned role is basic viewer."
gcloud compute instances create lab-2 \
    --zone $ZONE2 \
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
echo "export PROJECTID2=$PROJECTID2" >> ~/.bashrc
. ~/.bashrc
echo -e "\n👉  User 2 $USERID2 doesn't have access to Project ID 2 $PROJECTID2"
printf 'n\n' | script -qec "gcloud config set project $PROJECTID2" /dev/null
echo "🟢  Warning is expected. Did't set Project ID 2."

gcloud config configurations activate default
sudo yum -y install epel-release
sudo yum -y install jq
echo "export USERID2=$USERID2" >> ~/.bashrc
. ~/.bashrc
gcloud projects add-iam-policy-binding $PROJECTID2 \
    --member user:$USERID2 \
    --role=roles/viewer


cat << 'EOF'

========================================================
Task 4. Test that user2 has access
========================================================

EOF

gcloud config configurations activate user2
gcloud config set project $PROJECTID2

echo -e "\n👉  Project ID 2 $PROJECTID2 VM instances:"
gcloud compute instances list

echo -e "\n👉  User 2 $USERID2 cannot create an instance in the 2nd project, as the assigned role is basic viewer."
gcloud compute instances create lab-2 \
    --zone $ZONE2 \
    --machine-type=e2-standard-2 || true
echo "🟢  Error is expected."

gcloud config configurations activate default
gcloud iam roles create devops \
    --project $PROJECTID2 \
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
until gcloud iam roles describe devops --project $PROJECTID2 >/dev/null 2>&1
do sleep 5; done

gcloud projects add-iam-policy-binding $PROJECTID2 \
    --member=user:$USERID2 \
    --role=roles/iam.serviceAccountUser
until gcloud projects get-iam-policy $PROJECTID2 \
  --flatten="bindings[].members" \
  --format="value(bindings.role, bindings.members)" 2>/dev/null \
  | grep -q "roles/iam.serviceAccountUser.*$USERID2"
do sleep 5; done

gcloud projects add-iam-policy-binding $PROJECTID2 \
    --member=user:$USERID2 \
    --role=projects/$PROJECTID2/roles/devops
until gcloud projects get-iam-policy $PROJECTID2 \
  --flatten="bindings[].members" \
  --format="value(bindings.role, bindings.members)" 2>/dev/null \
  | grep -q "projects/$PROJECTID2/roles/devops.*$USERID2"
do sleep 5; done

gcloud config configurations activate user2
gcloud compute instances create lab-2 \
    --zone $ZONE2 \
    --machine-type=e2-standard-2 
echo -e '\n👉  Project ID 2 $PROJECTID2 VM instances:'
gcloud compute instances list

cat << 'EOF'

========================================================
Task 5. Using a service account
========================================================

EOF

gcloud config configurations activate default
gcloud config set project $PROJECTID2
gcloud iam service-accounts create devops --display-name devops
until gcloud iam service-accounts describe \
  "devops@$PROJECTID2.iam.gserviceaccount.com" >/dev/null 2>&1
do sleep 5; done

# gcloud iam service-accounts list --filter "displayName=devops"
export SA=$(gcloud iam service-accounts list \
    --format="value(email)" \
    --filter "displayName=devops")
gcloud projects add-iam-policy-binding $PROJECTID2 \
    --member serviceAccount:$SA \
    --role=roles/iam.serviceAccountUser


cat << 'EOF'

========================================================
Task 6. Using the service account with a compute instance
========================================================

EOF

gcloud projects add-iam-policy-binding $PROJECTID2 \
    --member serviceAccount:$SA \
    --role=roles/compute.instanceAdmin
until gcloud projects get-iam-policy "$PROJECTID2" \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:$SA AND bindings.role:roles/compute.instanceAdmin" \
  --format="value(bindings.role)" | grep -q .
do sleep 5; done

gcloud compute instances create lab-3 \
    --zone $ZONE2 \
    --machine-type=e2-standard-2 \
    --service-account $SA \
    --scopes="https://www.googleapis.com/auth/compute"


cat << 'EOF'

========================================================
Task 7. Test the service account
========================================================

EOF

gcloud compute ssh lab-3 \
    --zone $ZONE2 \
    --command "
gcloud config list &&
gcloud compute instances create lab-4 \
    --zone $ZONE2 \
    --machine-type=e2-standard-2 &&
echo -e '\n👉  Project ID 2 $PROJECTID2 VM instances:' &&
gcloud compute instances list
"

echo -e "\n✅  All done\n"