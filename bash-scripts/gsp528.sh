#!/bin/bash
## Created by nov05, 2026-08-07

export USER_ID=$(gcloud auth list --format="value(account)" --filter="status:ACTIVE")
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
  --format='value(projectNumber)')
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
# export ZONE2=$(gcloud compute zones list \
#   --filter="region:$REGION" \
#   --format="value(name)" | grep -v $ZONE | head -n 1)
# export BUCKET="$PROJECT_ID-bucket"
# export ORG_ID=$(gcloud projects get-ancestors $PROJECT_ID \
#   --format="value(id,type)" | awk '$2=="organization"{print $1}')
gcloud config set account $USER_ID
gcloud config set project $PROJECT_ID  
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
echo
echo "🔹  User: $USER"
echo "🔹  Username: $USER_ID"
echo "🔹  Project ID: $PROJECT_ID"
echo "🔹  Project number: $PROJECT_NUMBER"
echo "🔹  Region: $REGION"
echo "🔹  Zone: $ZONE"
# echo "🔹  Zone 2: $ZONE2"
# echo "🔹  Bukect: $BUCKET"
# echo "🔹  Organization ID: $ORG_ID"
echo
gcloud auth list


cat << 'EOF'

========================================================
Task 1. Connect 2 On-prem VPCs with NCC
========================================================

EOF

# Enable Network Connectivity API
gcloud services enable networkconnectivity.googleapis.com
until gcloud services list --enabled \
  --project=$PROJECT_ID | grep -q networkconnectivity.googleapis.com
do sleep 5; done


# Create NCC Hub
gcloud network-connectivity hubs create ncc-hub
gcloud network-connectivity hubs describe ncc-hub

# List VPN tunnels to identify preconfigured tunnel names
# Get all VPN tunnel names
VPN_TUNNELS=$(gcloud compute vpn-tunnels list \
  --project=$PROJECT_ID \
  --format="value(name)")
# Store tunnel names
OFFICE1_TUNNEL1=$(echo "$VPN_TUNNELS" | sed -n '1p')
OFFICE1_TUNNEL2=$(echo "$VPN_TUNNELS" | sed -n '2p')
OFFICE2_TUNNEL1=$(echo "$VPN_TUNNELS" | sed -n '3p')
OFFICE2_TUNNEL2=$(echo "$VPN_TUNNELS" | sed -n '4p')
# Verify values
echo $OFFICE1_TUNNEL1
echo $OFFICE1_TUNNEL2
echo $OFFICE2_TUNNEL1
echo $OFFICE2_TUNNEL2

## Create On-Prem Office 1 spoke
## The spoke corresponding to On-Prem Office 1 must have office-1 included in its name.
gcloud network-connectivity spokes linked-vpn-tunnels create office-1-spoke \
  --hub=ncc-hub \
  --vpn-tunnel=$OFFICE1_TUNNEL1 \
  --vpn-tunnel=$OFFICE1_TUNNEL2 \
  --region=$REGION

## Create On-Prem Office 2 spoke
## The spoke corresponding to On-Prem Office 2 must have office-2 included in its name.
gcloud network-connectivity spokes linked-vpn-tunnels create office-2-spoke \
  --hub=ncc-hub \
  --vpn-tunnel=$OFFICE2_TUNNEL1 \
  --vpn-tunnel=$OFFICE2_TUNNEL2 \
  --region=$REGION

gcloud network-connectivity spokes list \
  --hub=ncc-hub \
  --region=$REGION

gcloud network-connectivity hubs route-tables routes list \
  --hub=ncc-hub \
  --route_table=default

gcloud compute ssh $OFFICE1_VM \
  --zone=$ZONE \
  --project=$PROJECT_ID \
  --command="ping $OFFICE2_VM_INTERNAL_IP"

gcloud compute ssh <OFFICE_2_VM_NAME> \
  --zone=$ZONE \
  --project=$PROJECT_ID \
  --command="ping <OFFICE_1_VM_INTERNAL_IP>"


cat << 'EOF'

========================================================
Task 2. Connect VPC to VPC
========================================================

EOF

# List VPC networks
gcloud compute networks list

# Configure Workload VPC 1 as an NCC spoke
gcloud network-connectivity spokes linked-vpc-network create workload-1-spoke \
  --hub=ncc-hub \
  --vpc-network=<WORKLOAD_VPC_1_NAME> \
  --global

# Configure Workload VPC 2 as an NCC spoke

gcloud network-connectivity spokes linked-vpc-network create workload-2-spoke \
--hub=ncc-hub \
--vpc-network=<WORKLOAD_VPC_2_NAME> \
--global


# Verify NCC spokes

gcloud network-connectivity spokes list \
--hub=ncc-hub \
--global


# Verify NCC routes

gcloud network-connectivity hubs route-tables routes list \
--hub=ncc-hub \
--route_table=default


# List VM instances and internal IP addresses

gcloud compute instances list \
--format="table(name,networkInterfaces.networkIP,zone)"


# Test connectivity from Workload VPC 1 VM to Workload VPC 2 VM

gcloud compute ssh <WORKLOAD_1_VM_NAME> \
--zone=$ZONE \
--project=$PROJECT_ID \
--command="ping <WORKLOAD_2_VM_INTERNAL_IP>"




cat << 'EOF'

========================================================
Task 3. Connect VPC to On-prem
========================================================

EOF


echo -e "\n✅  All done\n"