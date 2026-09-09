#!/bin/bash
## Created by nov05, 2026-09-09

export USER_ID=$(gcloud auth list --format="value(account)" --filter="status:ACTIVE")
export PROJECT_ID=$(gcloud config get-value project)
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

gcloud config set account $USER_ID
gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

echo
echo "🔹  User: $USER"
echo "🔹  Username: $USER_ID"
echo "🔹  Project ID: $PROJECT_ID"
echo "🔹  Region: $REGION"
echo "🔹  Zone: $ZONE"
echo

cat << 'EOF'

========================================================
Task 1. Create the web servers
========================================================

EOF

# Create blue server with web-server network tag
gcloud compute instances create blue \
  --zone="$ZONE" \
  --machine-type=e2-micro \
  --tags=web-server \
  --image-family=debian-12 \
  --image-project=debian-cloud
until gcloud compute ssh blue \
    --zone="$ZONE" \
    --command="echo Instance is ready." \
    --quiet 2>/dev/null
do sleep 5; done

# Create green server without a network tag
gcloud compute instances create green \
  --zone="$ZONE" \
  --machine-type=e2-micro \
  --image-family=debian-12 \
  --image-project=debian-cloud
until gcloud compute ssh green \
    --zone="$ZONE" \
    --command="echo Instance is ready." \
    --quiet 2>/dev/null
do sleep 5; done

# Install nginx and customize blue
gcloud compute ssh blue --zone="$ZONE" --command='
sudo apt-get install nginx-light -y
sudo sed -i "s/<h1>Welcome to nginx!<\/h1>/<h1>Welcome to the blue server!<\/h1>/" /var/www/html/index.nginx-debian.html
cat /var/www/html/index.nginx-debian.html
'

# Install nginx and customize green
gcloud compute ssh green --zone="$ZONE" --command='
sudo apt-get install nginx-light -y
sudo sed -i "s/<h1>Welcome to nginx!<\/h1>/<h1>Welcome to the green server!<\/h1>/" /var/www/html/index.nginx-debian.html
cat /var/www/html/index.nginx-debian.html
'

cat << 'EOF'

========================================================
Task 2. Create the firewall rule
========================================================

EOF

# Create the tagged firewall rule
gcloud compute firewall-rules create allow-http-web-server \
  --network=default \
  --target-tags=web-server \
  --source-ranges=0.0.0.0/0 \
  --allow=tcp:80,icmp
until gcloud compute firewall-rules describe allow-http-web-server \
    --format="value(name)" 2>/dev/null | grep -q "^allow-http-web-server$"
do sleep 2; done

# Create test-vm
gcloud compute instances create test-vm --machine-type=e2-micro --subnet=default --zone="$ZONE"
until gcloud compute ssh test-vm \
    --zone="$ZONE" \
    --command="echo Instance is ready." \
    --quiet 2>/dev/null
do sleep 5; done

# Test HTTP connectivity from test-vm
BLUE_INTERNAL_IP=$(gcloud compute instances describe blue --zone="$ZONE" --format='get(networkInterfaces[0].networkIP)')
GREEN_INTERNAL_IP=$(gcloud compute instances describe green --zone="$ZONE" --format='get(networkInterfaces[0].networkIP)')
BLUE_EXTERNAL_IP=$(gcloud compute instances describe blue --zone="$ZONE" --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
GREEN_EXTERNAL_IP=$(gcloud compute instances describe green --zone="$ZONE" --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

echo "Blue internal IP: $BLUE_INTERNAL_IP"
echo "Green internal IP: $GREEN_INTERNAL_IP"
echo "Blue external IP: $BLUE_EXTERNAL_IP"
echo "Green external IP: $GREEN_EXTERNAL_IP"

gcloud compute ssh test-vm --zone="$ZONE" --command="
echo '--- blue internal ---'
curl $BLUE_INTERNAL_IP
echo
echo '--- green internal ---'
curl -c 3 $GREEN_INTERNAL_IP
echo
echo '--- blue external ---'
curl $BLUE_EXTERNAL_IP
"

cat << 'EOF'

========================================================
Task 3. Explore the Network and Security Admin roles
========================================================

Question 1: The Network Admin role provides permissions to:
Answer: List the available firewall rules

Question 2: The Security Admin role provides permissions to:
Answer: List, create, modify, and delete the available firewall rules

EOF

# Create the Network-admin service account
gcloud iam service-accounts create Network-admin \
  --display-name="Network-admin"
until gcloud iam service-accounts describe \
  "Network-admin@$PROJECT_ID.iam.gserviceaccount.com" >/dev/null 2>&1
do sleep 5; done

# Grant Compute Network Admin role
NETWORK_ADMIN_SA="Network-admin@${PROJECT_ID}.iam.gserviceaccount.com"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${NETWORK_ADMIN_SA}" \
  --role="roles/compute.networkAdmin"
until gcloud projects get-iam-policy "$PROJECT_ID" \
  --flatten="bindings[].members" \
  --format="value(bindings.role, bindings.members)" 2>/dev/null \
  | grep -q "roles/compute.networkAdmin.*${NETWORK_ADMIN_SA}"
do sleep 5; done

# ⚠️ Stop test-vm
gcloud compute instances stop test-vm \
  --zone="$ZONE" \
  --quiet
until gcloud compute instances describe test-vm \
  --zone="$ZONE" \
  --format="value(status)" 2>/dev/null \
  | grep -q "^TERMINATED$"
do sleep 5; done

# Authorize test-vm to use the Network-admin service account
gcloud compute instances set-service-account test-vm \
  --zone="$ZONE" \
  --service-account="$NETWORK_ADMIN_SA" \
  --scopes=https://www.googleapis.com/auth/cloud-platform
until gcloud compute instances describe test-vm \
  --zone="$ZONE" \
  --format="value(serviceAccounts.email)" 2>/dev/null \
  | grep -q "^${NETWORK_ADMIN_SA}$"
do sleep 5; done

# ⚠️ Start test-vm
gcloud compute instances start test-vm \
  --zone="$ZONE"
until gcloud compute instances describe test-vm \
  --zone="$ZONE" \
  --format="value(status)" 2>/dev/null \
  | grep -q "^RUNNING$"
do sleep 5; done

# Verify Network Admin permissions
gcloud compute firewall-rules list
# Network Admin cannot delete firewall rules
gcloud compute firewall-rules delete allow-http-web-server --quiet || true

# Update Network-admin to Security Admin
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${NETWORK_ADMIN_SA}" \
  --role="roles/compute.securityAdmin"
until gcloud projects get-iam-policy "$PROJECT_ID" \
  --flatten="bindings[].members" \
  --format="value(bindings.role, bindings.members)" 2>/dev/null \
  | grep -q "roles/compute.securityAdmin.*${NETWORK_ADMIN_SA}"
do sleep 5; done

# Verify Security Admin permissions
gcloud compute firewall-rules list
# Delete the firewall rule
gcloud compute firewall-rules delete allow-http-web-server --quiet
until ! gcloud compute firewall-rules describe allow-http-web-server \
  >/dev/null 2>&1
do sleep 5; done
# Verify that external HTTP access to blue is no longer available
gcloud compute ssh test-vm --zone="$ZONE" --command="
curl -c 3 $BLUE_EXTERNAL_IP
" || true

echo -e "\n✅  All done\n"