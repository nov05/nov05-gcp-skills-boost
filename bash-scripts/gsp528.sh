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

echo -e "\n\n$ gcloud compute networks list --format=\"value(name)\""
gcloud compute networks list --format="value(name)"
echo -e "\n$ gcloud compute instances list --format=\"value(name)\""
gcloud compute instances list --format="value(name)"
echo -e "\n$ gcloud compute vpn-tunnels list --project=$PROJECT_ID --format=\"value(name)\""
gcloud compute vpn-tunnels list --project=$PROJECT_ID --format="value(name)"
echo

: << 'EOF'
$ gcloud compute networks list --format="value(name)"
on-prem-office-1-vpc
on-prem-office-2-vpc
routing-vpc
workload-vpc-1
workload-vpc-2

$ gcloud compute instances list --format="value(name)"
cloudsql-client
onprem-office1-vm
onprem-office2-vm
workload1-vm
workload2-vm

$ gcloud compute vpn-tunnels list --project=$PROJECT_ID --format="value(name)"
onprem-office1-to-routing-tunnel-0
onprem-office1-to-routing-tunnel-1
onprem-office2-to-routing-tunnel-0
onprem-office2-to-routing-tunnel-1
routing-to-onprem-office1-tunnel-0
routing-to-onprem-office1-tunnel-1
routing-to-onprem-office2-tunnel-0
routing-to-onprem-office2-tunnel-1
EOF





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

## Create On-Prem Office 1 spoke
## The spoke corresponding to On-Prem Office 1 must have office-1 included in its name.
if gcloud network-connectivity spokes describe office-1-spoke \
  --region=$REGION >/dev/null 2>&1; then
  gcloud network-connectivity spokes delete office-1-spoke \
    --region=$REGION \
    --quiet
fi
## If you omit --site-to-site-data-transfer, site-to-cloud behavior is configured by default.
gcloud network-connectivity spokes linked-vpn-tunnels create office-1-spoke \
  --region=$REGION \
  --hub=ncc-hub \
  --vpn-tunnels=routing-to-onprem-office1-tunnel-0,routing-to-onprem-office1-tunnel-1 \
  --site-to-site-data-transfer 

## Create On-Prem Office 2 spoke
## The spoke corresponding to On-Prem Office 2 must have office-2 included in its name.
if gcloud network-connectivity spokes describe office-2-spoke \
  --region=$REGION >/dev/null 2>&1; then
  gcloud network-connectivity spokes delete office-2-spoke \
    --region=$REGION \
    --quiet
fi
gcloud network-connectivity spokes linked-vpn-tunnels create office-2-spoke \
  --region=$REGION \
  --hub=ncc-hub \
  --vpn-tunnels=routing-to-onprem-office2-tunnel-0,routing-to-onprem-office2-tunnel-1 \
  --site-to-site-data-transfer

## 👉 Check my progress

## Verify NCC spokes
gcloud network-connectivity spokes list \
  --region=$REGION
gcloud network-connectivity hubs route-tables routes list \
  --hub=ncc-hub \
  --route_table=default

## Test connectivity between On-Prem Office 1 and On-Prem Office 2 VMs
OFFICE2_VM_INTERNAL_IP=$(gcloud compute instances describe onprem-office2-vm \
  --zone=$ZONE \
  --project=$PROJECT_ID \
  --format="value(networkInterfaces[0].networkIP)")
gcloud compute ssh onprem-office1-vm \
  --zone=$ZONE \
  --project=$PROJECT_ID \
  --command="ping -c 4 -W 2 $OFFICE2_VM_INTERNAL_IP" \
  --quiet

## Test connectivity between On-Prem Office 2 and On-Prem Office 1 VMs
OFFICE1_VM_INTERNAL_IP=$(gcloud compute instances describe onprem-office1-vm \
  --zone=$ZONE \
  --project=$PROJECT_ID \
  --format="value(networkInterfaces[0].networkIP)")
gcloud compute ssh onprem-office2-vm \
  --zone=$ZONE \
  --project=$PROJECT_ID \
  --command="ping -c 4 -W 2 $OFFICE1_VM_INTERNAL_IP" \
  --quiet


cat << 'EOF'

========================================================
Task 2. Connect VPC to VPC
========================================================

EOF

## Configure Workload VPC 1 as an NCC spoke
## The spoke corresponding to Workload VPC 1 must have workload-1 included in its name.
if gcloud network-connectivity spokes describe workload-1-spoke \
  --global >/dev/null 2>&1; then
  gcloud network-connectivity spokes delete workload-1-spoke \
    --global \
    --quiet
fi
gcloud network-connectivity spokes linked-vpc-network create workload-1-spoke \
  --hub=ncc-hub \
  --vpc-network=workload-vpc-1 \
  --global

## Configure Workload VPC 2 as an NCC spoke
## The spoke corresponding to Workload VPC 2 must have workload-2 included in its name.
if gcloud network-connectivity spokes describe workload-2-spoke \
  --global >/dev/null 2>&1; then
  gcloud network-connectivity spokes delete workload-2-spoke \
    --global \
    --quiet
fi
gcloud network-connectivity spokes linked-vpc-network create workload-2-spoke \
  --hub=ncc-hub \
  --vpc-network=workload-vpc-2 \
  --global

# Verify NCC spokes
gcloud network-connectivity spokes list \
  --hub=ncc-hub \
  --global

# Verify NCC routes
gcloud network-connectivity hubs route-tables routes list \
  --hub=ncc-hub \
  --route_table=default

# Test connectivity from Workload VPC 1 VM to Workload VPC 2 VM
WORKLOAD_2_VM_INTERNAL_IP=$(gcloud compute instances describe workload2-vm \
  --zone=$ZONE \
  --project=$PROJECT_ID \
  --format="value(networkInterfaces[0].networkIP)")
gcloud compute ssh workload1-vm \
  --zone=$ZONE \
  --project=$PROJECT_ID \
  --command="ping -c 4 -W 2 $WORKLOAD_2_VM_INTERNAL_IP"

# Test connectivity from Workload VPC 2 VM to Workload VPC 1 VM
WORKLOAD1_VM_INTERNAL_IP=$(gcloud compute instances describe workload1-vm \
  --zone=$ZONE \
  --project=$PROJECT_ID \
  --format="value(networkInterfaces[0].networkIP)")
gcloud compute ssh workload2-vm \
  --zone=$ZONE \
  --project=$PROJECT_ID \
  --command="ping -c 4 -W 2 $WORKLOAD1_VM_INTERNAL_IP"





cat << 'EOF'

========================================================
Task 3. Connect VPC to On-prem
========================================================

EOF

## Create the hybrid spoke for On-Prem Office 1
if gcloud network-connectivity spokes describe hybrid-office-1 \
  --global >/dev/null 2>&1; then
  gcloud network-connectivity spokes delete hybrid-office-1 \
    --global \
    --quiet
fi
gcloud network-connectivity spokes linked-vpc-network create hybrid-office-1 \
  --hub=ncc-hub \
  --vpc-network=on-prem-office-1-vpc \
  --global

## Create the hybrid spoke for Workload VPC 1
if gcloud network-connectivity spokes describe hybrid-workload-1 \
  --global >/dev/null 2>&1; then
  gcloud network-connectivity spokes delete hybrid-workload-1 \
    --global \
    --quiet
fi
gcloud network-connectivity spokes linked-vpc-network create hybrid-workload-1 \
  --hub=ncc-hub \
  --vpc-network=workload-vpc-1 \
  --global

## Verify NCC spokes
gcloud network-connectivity spokes list --global
gcloud network-connectivity spokes describe hybrid-office-1 --global
gcloud network-connectivity spokes describe hybrid-workload-1 --global

## Verify NCC connectivity between Workload VPC 1 and On-Prem Office 1
OFFICE1_VM_INTERNAL_IP=$(gcloud compute instances describe onprem-office1-vm \
  --zone=$ZONE \
  --project=$PROJECT_ID \
  --format="value(networkInterfaces[0].networkIP)")
gcloud compute ssh workload1-vm \
  --zone=$ZONE \
  --project=$PROJECT_ID \
  --command="ping -c 4 -W 2 $OFFICE1_VM_INTERNAL_IP"

## Verify NCC connectivity between Workload VPC 2 and On-Prem Office 2
WORKLOAD2_VM_INTERNAL_IP=$(gcloud compute instances describe workload2-vm \
  --zone=$ZONE \
  --project=$PROJECT_ID \
  --format="value(networkInterfaces[0].networkIP)")
gcloud compute ssh workload2-vm \
  --zone=$ZONE \
  --project=$PROJECT_ID \
  --command="ping -c 4 -W 2 $WORKLOAD2_VM_INTERNAL_IP"



echo -e "\n✅  All done\n"